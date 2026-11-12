"""Release adapters execute fake tools only, never authenticate with Apple."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import tempfile
import unittest

REPO=Path(__file__).resolve().parents[1]

class ReleaseCommandTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='iosipa-release-')
        self.addCleanup(self.temp.cleanup)
        self.root=Path(self.temp.name).resolve()
        self.app=self.root/'App with spaces'
        (self.app/'fastlane').mkdir(parents=True)
        (self.app/'fastlane/Fastfile').write_text('existing workflow')
        (self.app/'fastlane/.env').write_text('APP_IDENTIFIER=com.test.app\n')
        self.bin=self.root/'bin';self.bin.mkdir()
        self.capture=self.root/'action.json'
        self.bundle_calls=self.root/'bundle.jsonl'
        self.env=dict(os.environ,PATH=str(self.bin)+os.pathsep+os.environ['PATH'],CAPTURE=str(self.capture),IOSIPA_TEST_BUNDLE_CALLS=str(self.bundle_calls))
        self.tool('fastlane', '''import os,sys,json
from pathlib import Path
Path(os.environ['CAPTURE']).write_text(json.dumps({'args':sys.argv[1:],'cwd':os.getcwd(),'gemfile':os.environ.get('BUNDLE_GEMFILE'),'ci':os.environ.get('CI'),'key':os.environ.get('APP_STORE_KEY_ID')}))
sys.exit(9 if os.environ.get('FAIL_ACTION') else 0)
''')
        self.tool('bundle', '''import os,sys,json,subprocess
from pathlib import Path
with Path(os.environ['IOSIPA_TEST_BUNDLE_CALLS']).open('a') as f:f.write(json.dumps(sys.argv[1:])+'\\n')
if sys.argv[1]=='check':sys.exit(1 if os.environ.get('MISSING_GEMS') else 0)
if sys.argv[1]=='install':sys.exit(1 if os.environ.get('FAIL_INSTALL') else 0)
if sys.argv[1]=='exec':sys.exit(subprocess.call(sys.argv[2:]))
raise RuntimeError('Unexpected bundle command')
''')

    def tool(self,name,body):
        p=self.bin/name;p.write_text('#!'+sys.executable+'\n'+body);p.chmod(0o755)

    def run_cli(self,command,*options,env=None,cwd=None):
        return subprocess.run(['bash',str(REPO/'scripts/install.sh'),command,*map(str,options)],
                              cwd=cwd or self.app,env=env or self.env,text=True,capture_output=True,timeout=30)

    def result(self):return json.loads(self.capture.read_text())

    def test_help_does_not_need_project_or_credentials(self):
        for command in ['testflight','metadata','submit']:
            result=self.run_cli(command,'--help',cwd=self.root)
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertIn(command,result.stdout)
        self.assertFalse(self.capture.exists())

    def test_testflight_forwards_flags_as_literal_values(self):
        notes='Test "notes"; $(touch should-not-exist)'
        result=self.run_cli('testflight','--scheme','App Name','--project','ios/App.xcodeproj','--version','2.0','--build-number','18','--changelog',notes)
        self.assertEqual(result.returncode,0,result.stderr)
        args=self.result()['args']
        self.assertEqual(args[:2],['ios','testflight_only'])
        self.assertIn('scheme:App Name',args)
        self.assertIn('beta_description:'+notes,args)
        self.assertIn('project:ios/App.xcodeproj',args)
        self.assertFalse((self.app/'should-not-exist').exists())

    def test_external_distribution_enforces_processing_and_groups(self):
        result=self.run_cli('testflight','--external','--groups','External')
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn('skip_waiting_for_build_processing:false',self.result()['args'])
        self.capture.unlink()
        for flags in [('--external',),('--external','--groups','External','--no-wait')]:
            result=self.run_cli('testflight',*flags)
            self.assertNotEqual(result.returncode,0)
            self.assertFalse(self.capture.exists())

    def test_metadata_forwards_explicit_asset_choices_without_build_flags(self):
        result=self.run_cli('metadata','--no-metadata','--screenshots','--app-identifier','com.test.assets')
        self.assertEqual(result.returncode,0,result.stderr)
        args=self.result()['args']
        self.assertEqual(args[:2],['ios','metadata_only'])
        self.assertIn('upload_metadata:false',args)
        self.assertIn('upload_screenshots:true',args)
        result=self.run_cli('metadata','--scheme','Wrong')
        self.assertNotEqual(result.returncode,0)

    def test_submit_requires_exact_build_and_preserves_remote_assets_by_default(self):
        for flags in [(),('--version','2.0'),('--build-number','18')]:
            result=self.run_cli('submit',*flags)
            self.assertNotEqual(result.returncode,0)
            self.assertFalse(self.capture.exists())
        result=self.run_cli('submit','--version','2.0','--build-number','18')
        self.assertEqual(result.returncode,0,result.stderr)
        args=self.result()['args']
        self.assertEqual(args[:2],['ios','submit_review'])
        self.assertIn('build_number:18',args)
        self.assertNotIn('upload_metadata:true',args)
        self.assertNotIn('automatic_release:true',args)

    def test_submit_explicit_upload_and_automatic_release(self):
        result=self.run_cli('submit','--version','2.0','--build-number','18','--metadata','--screenshots','--automatic-release')
        self.assertEqual(result.returncode,0,result.stderr)
        for arg in ['upload_metadata:true','upload_screenshots:true','automatic_release:true']:
            self.assertIn(arg,self.result()['args'])

    def test_dry_run_never_calls_tools_or_displays_credentials(self):
        (self.app/'Gemfile').write_text('gem "fastlane"')
        env=dict(self.env,APP_STORE_KEY_ID='not-for-output',MISSING_GEMS='1')
        result=self.run_cli('submit','--version','2.0','--build-number','18','--dry-run',env=env)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn('bundle exec fastlane ios submit_review',result.stdout)
        self.assertNotIn('not-for-output',result.stdout+result.stderr)
        self.assertFalse(self.capture.exists());self.assertFalse(self.bundle_calls.exists())

    def test_bundle_uses_target_gemfile_and_installs_missing_dependencies(self):
        (self.app/'Gemfile').write_text('gem "fastlane"')
        env=dict(self.env,MISSING_GEMS='1',BUNDLE_GEMFILE='/unrelated/Gemfile',APP_STORE_KEY_ID='inherited-key')
        result=self.run_cli('testflight','--non-interactive',env=env)
        self.assertEqual(result.returncode,0,result.stderr)
        captured=self.result()
        self.assertEqual(captured['gemfile'],str(self.app/'Gemfile'))
        self.assertEqual(captured['key'],'inherited-key');self.assertEqual(captured['ci'],'true')
        calls=[json.loads(line) for line in self.bundle_calls.read_text().splitlines()]
        self.assertEqual(calls[:2],[['check'],['install']])
        self.assertEqual(captured['cwd'],str(self.app))

    def test_gem_install_failure_stops_before_upload(self):
        (self.app/'Gemfile').write_text('gem "fastlane"')
        result=self.run_cli('testflight',env=dict(self.env,MISSING_GEMS='1',FAIL_INSTALL='1'))
        self.assertNotEqual(result.returncode,0);self.assertFalse(self.capture.exists())

    def test_missing_setup_does_not_install_or_overwrite_files(self):
        (self.app/'fastlane/Fastfile').unlink()
        result=self.run_cli('metadata')
        self.assertNotEqual(result.returncode,0)
        self.assertIn('Release setup not found',result.stderr)
        self.assertFalse((self.app/'fastlane/Fastfile').exists())
        self.assertFalse((self.app/'Gemfile').exists())

    def test_action_failure_and_existing_files_are_preserved(self):
        before={name:(self.app/name).read_bytes() for name in ['fastlane/Fastfile','fastlane/.env']}
        result=self.run_cli('testflight',env=dict(self.env,FAIL_ACTION='1'))
        self.assertNotEqual(result.returncode,0)
        for name,value in before.items():self.assertEqual((self.app/name).read_bytes(),value)

    def test_explicit_project_directory(self):
        result=self.run_cli('metadata',self.app,'--dry-run',cwd=self.root)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn(str(self.app),result.stdout)

    def test_downloaded_dispatcher_handles_release_command(self):
        archive=self.root/'source.tar.gz'
        with tarfile.open(archive,'w:gz') as tar:
            tar.add(REPO/'scripts/release.rb',arcname='template/scripts/release.rb')
            tar.add(REPO/'ios-newapp-template',arcname='template/ios-newapp-template')
        launcher=self.root/'install.sh';shutil.copyfile(REPO/'scripts/install.sh',launcher)
        result=subprocess.run(['bash',str(launcher),'submit',str(self.app),'--version','2.0','--build-number','18','--dry-run'],
                              env=dict(self.env,LOCAL_ARCHIVE_PATH=str(archive)),text=True,capture_output=True,timeout=30)
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn('submit_review',result.stdout);self.assertFalse(self.capture.exists())

if __name__=='__main__':unittest.main(verbosity=2)
