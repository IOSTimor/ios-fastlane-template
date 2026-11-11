"""One-command builder regressions. Xcode and fastlane are replaced with executable fixtures."""
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import tarfile
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
BUILDER = REPO / 'scripts/build_local.rb'

APP_SETTINGS = {
    'PRODUCT_TYPE': 'com.apple.product-type.application',
    'WRAPPER_EXTENSION': 'app',
    'SUPPORTED_PLATFORMS': 'iphoneos iphonesimulator',
    'DEVELOPMENT_TEAM': 'TEAM123456',
    'PRODUCT_BUNDLE_IDENTIFIER': 'com.test.fixture',
    'CODE_SIGN_STYLE': 'Automatic',
}


class LocalBuilderTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='one-command-ipa-')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.app = self.root / 'Project with spaces'
        self.app.mkdir()
        (self.app / 'Unrelated.xcodeproj').mkdir()
        (self.app / 'ios').mkdir()
        (self.app / 'ios/Actual App.xcworkspace').mkdir()
        (self.app / 'Pods/Pods.xcodeproj').mkdir(parents=True)
        (self.app / 'Unrelated.xcodeproj/project.xcworkspace').mkdir()
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.config = self.root / 'xcode.json'
        self.capture = self.root / 'fastlane.json'
        self.xcode_calls = self.root / 'xcode_calls.jsonl'
        self.write_config({'Library': [{'buildSettings': {'PRODUCT_TYPE': 'com.apple.product-type.framework', 'SUPPORTED_PLATFORMS': 'iphoneos'}}],
                           'RealScheme': [{'buildSettings': APP_SETTINGS}]})
        self.executable('xcodebuild', '''import json, os, sys
from pathlib import Path
config=json.loads(Path(os.environ['XCODE_FIXTURE']).read_text())
args=sys.argv[1:]
with Path(os.environ['XCODE_CALLS']).open('a') as f: f.write(json.dumps(args)+'\\n')
if '-list' in args:
 print(json.dumps({'workspace': {'schemes': list(config)}}))
else:
 scheme=args[args.index('-scheme')+1]
 if config[scheme] == 'error':
  print('Scheme inspection failed', file=sys.stderr); sys.exit(65)
 print(json.dumps(config[scheme]))
''')
        self.executable('fastlane', '''import json, os, sys, plistlib
from pathlib import Path
args=sys.argv[1:]
options=dict(arg.split(':',1) for arg in args[2:])
plist=plistlib.loads(Path(options['export_options']).read_bytes())
Path(os.environ['FASTLANE_CAPTURE']).write_text(json.dumps({'args':args, 'plist':plist, 'cwd':os.getcwd(),
 'bundle':os.environ.get('BUNDLE_GEMFILE'), 'gym':os.environ.get('GYM_EXPORT_OPTIONS')}))
if os.environ.get('FAIL_BUILD'): sys.exit(65)
if not os.environ.get('MISSING_IPA'):
 output=Path(options['output_directory'])/options['output_name']
 output.parent.mkdir(parents=True,exist_ok=True)
 output.write_bytes(b'fixture IPA')
''')
        self.env = dict(os.environ, PATH=str(self.bin)+os.pathsep+os.environ['PATH'],
                        XCODE_FIXTURE=str(self.config), XCODE_CALLS=str(self.xcode_calls),
                        FASTLANE_CAPTURE=str(self.capture))

    def executable(self, name, code):
        path = self.bin / name
        path.write_text('#!' + sys.executable + '\n' + code)
        path.chmod(0o755)

    def write_config(self, schemes):
        self.config.write_text(json.dumps(schemes))

    def run_builder(self, *args, env=None, cwd=None):
        return subprocess.run(['ruby', str(BUILDER), *map(str,args)], cwd=cwd or self.app,
                              env=env or self.env, text=True, capture_output=True, timeout=30)

    def test_default_current_directory_uses_workspace_and_actual_app_scheme(self):
        result = self.run_builder('--non-interactive')
        self.assertEqual(result.returncode, 0, result.stdout+result.stderr)
        captured=json.loads(self.capture.read_text())
        self.assertIn('workspace:'+str(self.app/'ios/Actual App.xcworkspace'),captured['args'])
        self.assertIn('scheme:RealScheme',captured['args'])
        self.assertEqual(captured['args'][:2],['run','build_app'])
        self.assertEqual(captured['plist']['destination'],'export')
        self.assertEqual(captured['plist']['method'],'development')
        self.assertEqual(captured['plist']['teamID'],'TEAM123456')
        self.assertIn('xcargs:-allowProvisioningUpdates',captured['args'])
        self.assertNotEqual(captured['cwd'],str(self.app))
        self.assertFalse((self.app/'fastlane').exists())
        self.assertFalse((self.app/'Gemfile').exists())
        self.assertEqual(len(list((self.app/'build').glob('RealScheme-*.ipa'))),1)

    def test_multiple_application_schemes_fail_without_building(self):
        self.write_config({name:[{'buildSettings':APP_SETTINGS}] for name in ['AppA','AppB']})
        result=self.run_builder('--non-interactive')
        self.assertNotEqual(result.returncode,0)
        self.assertIn('--scheme NAME',result.stderr)
        self.assertFalse(self.capture.exists())
        result=self.run_builder('--non-interactive','--scheme','AppB')
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn('scheme:AppB',json.loads(self.capture.read_text())['args'])

    def test_multiple_containers_require_choice_and_explicit_project_overrides_workspace(self):
        (self.app/'Other.xcworkspace').mkdir()
        result=self.run_builder('--non-interactive')
        self.assertNotEqual(result.returncode,0)
        self.assertIn('--workspace PATH or --project PATH',result.stderr)
        self.assertFalse(self.capture.exists())
        result=self.run_builder('--project','Unrelated.xcodeproj','--non-interactive')
        self.assertEqual(result.returncode,0,result.stderr)
        captured=json.loads(self.capture.read_text())
        self.assertIn('project:'+str(self.app/'Unrelated.xcodeproj'),captured['args'])

    def test_dry_run_does_not_build_or_install(self):
        self.executable('brew','import sys\nraise RuntimeError("brew must not run")\n')
        result=self.run_builder('--dry-run','--non-interactive')
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn('Dry run complete',result.stdout)
        self.assertFalse(self.capture.exists())
        self.assertFalse((self.app/'build').exists())

    def test_inherited_gym_and_bundle_settings_do_not_affect_build(self):
        env=dict(self.env, BUNDLE_GEMFILE='/unrelated/Gemfile', GYM_EXPORT_OPTIONS='/unrelated/upload.plist')
        result=self.run_builder('--non-interactive',env=env)
        self.assertEqual(result.returncode,0,result.stderr)
        captured=json.loads(self.capture.read_text())
        self.assertIsNone(captured['bundle'])
        self.assertIsNone(captured['gym'])
        self.assertEqual(captured['plist']['destination'],'export')

    def test_manual_profiles_including_extensions_are_preserved(self):
        app=dict(APP_SETTINGS,CODE_SIGN_STYLE='Manual',PROVISIONING_PROFILE_SPECIFIER='App & Dev')
        extension={'PRODUCT_TYPE':'com.apple.product-type.app-extension','PRODUCT_BUNDLE_IDENTIFIER':'com.test.fixture.widget',
                   'PROVISIONING_PROFILE_SPECIFIER':'Widget Dev','SUPPORTED_PLATFORMS':'iphoneos'}
        self.write_config({'Manual App':[{'buildSettings':app},{'buildSettings':extension}]})
        result=self.run_builder('--non-interactive')
        self.assertEqual(result.returncode,0,result.stderr)
        captured=json.loads(self.capture.read_text())
        self.assertEqual(captured['plist']['signingStyle'],'manual')
        self.assertEqual(captured['plist']['provisioningProfiles'],{'com.test.fixture':'App & Dev','com.test.fixture.widget':'Widget Dev'})
        self.assertFalse(any(arg.startswith('xcargs:') for arg in captured['args']))

    def test_export_options_and_output_override(self):
        result=self.run_builder('--non-interactive','--export-method','ad-hoc','--configuration','Debug','--output-dir','artifacts/ipa','--no-provisioning-updates')
        self.assertEqual(result.returncode,0,result.stderr)
        captured=json.loads(self.capture.read_text())
        self.assertEqual(captured['plist']['method'],'ad-hoc')
        self.assertIn('configuration:Debug',captured['args'])
        self.assertIn('output_directory:'+str(self.app/'artifacts/ipa'),captured['args'])
        self.assertFalse(any(arg.startswith('xcargs:') for arg in captured['args']))

    def test_xcode_failure_and_library_only_project_do_not_build(self):
        self.write_config({'Broken':'error'})
        result=self.run_builder('--non-interactive','--scheme','Broken')
        self.assertNotEqual(result.returncode,0)
        self.assertIn('Xcode inspection failed',result.stderr)
        self.assertFalse(self.capture.exists())
        self.write_config({'Library':[{'buildSettings':{'PRODUCT_TYPE':'com.apple.product-type.framework','SUPPORTED_PLATFORMS':'iphoneos'}}]})
        result=self.run_builder('--non-interactive')
        self.assertNotEqual(result.returncode,0)
        self.assertIn('No unambiguous iOS application',result.stderr)

    def test_non_ios_application_is_not_selected_even_with_iphoneos_sdk_override(self):
        mac=dict(APP_SETTINGS,SUPPORTED_PLATFORMS='macosx',SDKROOT='iphoneos')
        self.write_config({'MacApp':[{'buildSettings':mac}],'RealScheme':[{'buildSettings':APP_SETTINGS}]})
        result=self.run_builder('--non-interactive')
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn('scheme:RealScheme',json.loads(self.capture.read_text())['args'])

    def test_xcode_embedded_errors_are_not_treated_as_success(self):
        self.write_config({'Broken':[{'buildSettings':{},'error':'Cannot read build settings'}]})
        result=self.run_builder('--non-interactive','--scheme','Broken')
        self.assertNotEqual(result.returncode,0)
        self.assertIn('Cannot read build settings',result.stderr)
        self.assertFalse(self.capture.exists())

    def test_failed_build_or_missing_ipa_returns_failure(self):
        for key in ['FAIL_BUILD','MISSING_IPA']:
            result=self.run_builder('--non-interactive',env=dict(self.env,**{key:'1'}))
            self.assertNotEqual(result.returncode,0)
            self.assertNotIn('IPA generated:',result.stdout)

    def test_missing_fastlane_is_installed_once_with_homebrew(self):
        source=(self.bin/'fastlane').read_text()
        (self.bin/'fastlane').unlink()
        (self.bin/'ruby').symlink_to(shutil.which('ruby'))
        (self.bin/'uname').symlink_to(shutil.which('uname'))
        script=self.root/'fastlane-source'
        script.write_text(source)
        self.executable('brew', "import os, sys, shutil\nfrom pathlib import Path\nassert sys.argv[1:]==['install','fastlane']\ndestination=Path(os.environ['FAKE_BIN'])/'fastlane'\nshutil.copyfile(os.environ['FASTLANE_SOURCE'], destination)\ndestination.chmod(0o755)\n")
        env=dict(self.env,PATH=str(self.bin),FAKE_BIN=str(self.bin),FASTLANE_SOURCE=str(script))
        result=self.run_builder('--non-interactive',env=env)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn('installing it with Homebrew',result.stdout)
        self.assertTrue(self.capture.exists())

    def test_existing_configuration_is_never_modified(self):
        (self.app/'fastlane').mkdir()
        files={'fastlane/Fastfile':'existing custom lane','fastlane/.env':'SCHEME=StaleScheme','Gemfile':'existing gemfile'}
        for name,value in files.items(): (self.app/name).write_text(value)
        result=self.run_builder('--non-interactive')
        self.assertEqual(result.returncode,0,result.stderr)
        for name,value in files.items(): self.assertEqual((self.app/name).read_text(),value)

    def test_installer_build_subcommand_dispatches_locally(self):
        result=subprocess.run(['bash',str(REPO/'scripts/install.sh'),'build',str(self.app),'--non-interactive','--dry-run'],
                              cwd=self.root,env=self.env,text=True,capture_output=True,timeout=30)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn('Scheme: RealScheme',result.stdout)
        self.assertFalse((self.app/'fastlane').exists())

    def test_downloaded_installer_supports_build_subcommand(self):
        archive=self.root/'template.tar.gz'
        with tarfile.open(archive,'w:gz') as tar:
            tar.add(REPO/'scripts/build_local.rb',arcname='template/scripts/build_local.rb')
            tar.add(REPO/'ios-newapp-template',arcname='template/ios-newapp-template')
        isolated=self.root/'install.sh'
        shutil.copyfile(REPO/'scripts/install.sh',isolated)
        env=dict(self.env,LOCAL_ARCHIVE_PATH=str(archive))
        result=subprocess.run(['bash',str(isolated),'build',str(self.app),'--non-interactive','--dry-run'],env=env,
                              text=True,capture_output=True,timeout=30)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn('Scheme: RealScheme',result.stdout)
        self.assertFalse((self.app/'fastlane').exists())

    def test_invalid_flags_and_missing_project_fail(self):
        for args in [('--scheme',),('--export-method','upload'),('--project','Missing.xcodeproj'),('--workspace','one','--project','two')]:
            result=self.run_builder(*args)
            self.assertNotEqual(result.returncode,0)
            self.assertFalse(self.capture.exists())


if __name__=='__main__':
    unittest.main(verbosity=2)
