"""Regression checks using temporary projects; never builds or contacts Apple."""
import hashlib
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tarfile
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
INSTALL = REPO / 'ios-newapp-template/scripts/create_project.sh'
FASTFILE = REPO / 'ios-newapp-template/fastlane/Fastfile'

# Only the DSL and explicit action doubles are available. No fastlane actions run.
RUBY_HARNESS = r'''
require "json"
module UI
  def self.message(*); end
  def self.important(*); end
  def self.success(*); end
  def self.user_error!(message); raise message; end
end
class Harness
  attr_reader :calls
  def initialize; @calls = []; end
  def default_platform(*); end
  def desc(*); end
  def platform(*); yield; end
  def lane(name, &block); define_singleton_method(name, &block); end
  alias private_lane lane
  def method_missing(name, *args)
    allowed = %i[build_app upload_to_testflight deliver increment_version_number increment_build_number produce app_store_connect_api_key get_ipa_info_plist_value]
    return super unless allowed.include?(name)
    @calls << [name, args.first || {}]
    return "fixture.ipa" if name == :build_app
    return {key_id: "fixture"} if name == :app_store_connect_api_key
    return args.first[:key] == "CFBundleVersion" ? "42" : "2.0.0" if name == :get_ipa_info_plist_value
  end
end
input = JSON.parse(STDIN.read)
%w[SCHEME PROJECT WORKSPACE APP_IDENTIFIER APPLE_ID FASTLANE_USER FASTLANE_SESSION APP_STORE_KEY_ID APP_STORE_ISSUER_ID APP_STORE_KEY_FILE EXPORT_OPTIONS_PLIST].each { |key| ENV.delete(key) }
input.fetch("env").each { |key, value| ENV[key] = value }
h = Harness.new
h.instance_eval(File.read(ARGV[0]), ARGV[0])
h.define_singleton_method(:project_path) { |path| File.expand_path(path, input.fetch("root")) }
h.define_singleton_method(:metadata_path) { File.join(input.fetch("root"), "fastlane", "metadata") }
h.define_singleton_method(:screenshots_path) { File.join(input.fetch("root"), "fastlane", "screenshots") }
options = input.fetch("options").each_with_object({}) { |(key, value), memo| memo[key.to_sym] = value }
error = nil
begin
  h.public_send(input.fetch("lane"), options)
rescue => exception
  error = exception.message
end
puts JSON.generate({calls: h.calls, error: error})
'''


class Fixture(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='ios-template-test-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.target = self.root / 'TargetApp'
        (self.target / 'TargetApp.xcodeproj').mkdir(parents=True)

    def run_command(self, args, **kwargs):
        return subprocess.run([str(arg) for arg in args], text=True, capture_output=True, timeout=60, **kwargs)

    def install(self, *args, target=None, env=None):
        return self.run_command(['bash', INSTALL, target or self.target, *args], env=env)


class InstallerTests(Fixture):
    def test_install_refuses_overwrite_and_preserves_existing_assets_and_env(self):
        self.assertEqual(self.install().returncode, 0)
        env = self.target / 'fastlane/.env'
        env.write_text('SCHEME=Customized\n')
        asset = self.target / 'fastlane/metadata/en-US/name.txt'
        asset.write_text('Customized name')
        self.assertNotEqual(self.install().returncode, 0)
        self.assertEqual(self.install('--force').returncode, 0)
        self.assertEqual(env.read_text(), 'SCHEME=Customized\n')
        self.assertEqual(asset.read_text(), 'Customized name')
        self.assertEqual(env.stat().st_mode & 0o777, 0o600)
        self.assertIn('fastlane/.env\n', (self.target / '.gitignore').read_text())

    def test_space_and_nested_paths(self):
        for name in ['Demo App.xcodeproj', 'ios/DemoApp.xcodeproj', 'ios/Demo & App.xcodeproj']:
            with self.subTest(name=name):
                target = self.root / ('case-' + str(len(list(self.root.iterdir()))))
                (target / name).mkdir(parents=True)
                result = self.install(target=target)
                self.assertEqual(result.returncode, 0, result.stderr)
                values = (target / 'fastlane/.env.default').read_text()
                expected = '"' + name + '"' if ' ' in name else name
                self.assertIn('PROJECT=' + expected + '\n', values)
                self.assertIn('APP_NAME=', values)
                self.assertNotIn('SCHEME=ios/', values)

    def test_empty_and_multiple_project_detection(self):
        target = self.root / 'Empty'
        target.mkdir()
        self.assertEqual(self.install(target=target).returncode, 0)
        (self.target / 'Other.xcodeproj').mkdir()
        result = self.install()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('Multiple projects detected', result.stdout)
        self.assertIn('\nPROJECT=\n', (self.target / 'fastlane/.env.default').read_text())

    def test_excludes_pods_and_project_internal_workspace(self):
        (self.target / 'Pods/Pods.xcodeproj').mkdir(parents=True)
        (self.target / 'TargetApp.xcodeproj/project.xcworkspace').mkdir()
        self.assertEqual(self.install().returncode, 0)
        values = (self.target / 'fastlane/.env.default').read_text()
        self.assertIn('PROJECT=TargetApp.xcodeproj\n', values)
        self.assertIn('WORKSPACE=\n', values)

    def test_legacy_root_env_imported_once(self):
        legacy = 'SCHEME=Legacy\nAPP_IDENTIFIER=com.test.legacy\n'
        (self.target / '.env').write_text(legacy)
        self.assertEqual(self.install().returncode, 0)
        self.assertEqual((self.target / 'fastlane/.env').read_text(), legacy)
        (self.target / '.env').write_text('SCHEME=Changed\n')
        self.assertEqual(self.install('--force').returncode, 0)
        self.assertEqual((self.target / 'fastlane/.env').read_text(), legacy)

    def test_missing_argument_and_skip_env(self):
        result = self.install('--scheme')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Missing value for --scheme', result.stderr)
        self.assertFalse((self.target / 'fastlane').exists())
        self.assertEqual(self.install('--skip-generate-env').returncode, 0)
        self.assertFalse((self.target / 'fastlane/.env').exists())

    def test_force_required_for_partial_setup(self):
        (self.target / 'fastlane').mkdir()
        (self.target / 'fastlane/Deliverfile').write_text('existing configuration')
        self.assertNotEqual(self.install().returncode, 0)

    @unittest.skipUnless(shutil.which('fastlane') or os.environ.get('FASTLANE_BIN'), 'fastlane is not installed')
    def test_actual_fastlane_reads_installed_env_and_special_characters(self):
        scheme = 'Demo & App # $SPECIAL_VALUE | "quoted"'
        self.assertEqual(self.install('--scheme', scheme).returncode, 0)
        env = dict(os.environ, FASTLANE_SKIP_UPDATE_CHECK='1', FASTLANE_OPT_OUT_USAGE='1', SPECIAL_VALUE='must-not-expand')
        for key in ['SCHEME', 'PROJECT', 'WORKSPACE']:
            env.pop(key, None)
        command = shlex.split(os.environ.get('FASTLANE_BIN', 'fastlane'))
        result = self.run_command([*command, 'ios', 'validate_setup'], cwd=self.target, env=env)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('Scheme default: ' + scheme, result.stdout)
        env_file = self.target / 'fastlane/.env'
        env_file.write_text(env_file.read_text().replace('SCHEME=', '#SCHEME=', 1) + '\nSCHEME=EditedScheme\n')
        result = self.run_command([*command, 'ios', 'validate_setup'], cwd=self.target, env=env)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('Scheme default: EditedScheme', result.stdout)

    def test_archive_refs_and_local_installer(self):
        archive = self.root / 'template.tar.gz'
        with tarfile.open(archive, 'w:gz') as tar:
            tar.add(REPO / 'ios-newapp-template', arcname='template/ios-newapp-template')
        fakebin = self.root / 'bin'
        fakebin.mkdir()
        curl = fakebin / 'curl'
        curl.write_text('#!' + sys.executable + '\nimport os, sys, shutil\n'
                        'from pathlib import Path\n'
                        'Path(os.environ["URL_CAPTURE"]).write_text(sys.argv[2])\n'
                        'shutil.copyfile(os.environ["FIXTURE_ARCHIVE"], sys.argv[sys.argv.index("-o")+1])\n')
        curl.chmod(0o755)
        for ref in ['main', 'v1.2.1', 'refs/tags/v1.2.1']:
            target = self.root / ref.replace('/', '_')
            (target / 'App.xcodeproj').mkdir(parents=True)
            env = dict(os.environ, PATH=str(fakebin) + os.pathsep + os.environ['PATH'], REPO_REF=ref,
                       FIXTURE_ARCHIVE=str(archive), URL_CAPTURE=str(self.root / 'url'))
            env.pop('LOCAL_ARCHIVE_PATH', None)
            env.pop('ARCHIVE_URL', None)
            result = self.run_command(['bash', REPO / 'scripts/install.sh', target], env=env)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual((self.root / 'url').read_text(), 'https://codeload.github.com/IOSTimor/ios-fastlane-template/tar.gz/' + ref)
            self.assertTrue((target / 'fastlane/Fastfile').exists())
        env = dict(os.environ, LOCAL_ARCHIVE_PATH=str(archive))
        self.assertEqual(self.run_command(['bash', REPO / 'scripts/install.sh', self.target], env=env).returncode, 0)

    def test_formula_updater_updates_url_version_ref_and_checksum(self):
        formula = self.root / 'formula.rb'
        shutil.copyfile(REPO / 'Formula/ios-fastlane-template.rb', formula)
        env = dict(os.environ, FORMULA_PATH=str(formula), INSTALL_SCRIPT_PATH=str(REPO / 'scripts/install.sh'))
        result = self.run_command(['bash', REPO / 'scripts/update_homebrew_formula.sh', '1.2.2'], env=env)
        self.assertEqual(result.returncode, 0, result.stderr)
        text = formula.read_text()
        self.assertIn('/v1.2.2/scripts/install.sh', text)
        self.assertIn('/v1.2.2/scripts/build_local.rb', text)
        self.assertIn(hashlib.sha256((REPO / 'scripts/build_local.rb').read_bytes()).hexdigest(), text)
        self.assertIn('version "1.2.2"', text)
        self.assertIn('REPO_REF="v1.2.2"', text)
        self.assertIn(hashlib.sha256((REPO / 'scripts/install.sh').read_bytes()).hexdigest(), text)

    def test_make_omits_empty_options_and_keeps_values_as_data(self):
        script = self.root / 'capture.py'
        script.write_text('import json, sys\nprint(json.dumps(sys.argv[1:]))\n')
        description = 'release "notes"; $(touch should-not-exist)'
        result = self.run_command(['make', '-s', '-f', REPO / 'ios-newapp-template/Makefile', 'release-existing',
                                   'FASTLANE=' + sys.executable + ' ' + str(script)],
                                  cwd=self.root, env=dict(os.environ, BETA_DESCRIPTION=description))
        self.assertEqual(result.returncode, 0, result.stderr)
        args = json.loads(result.stdout)
        self.assertEqual(args[:2], ['ios', 'release_existing'])
        self.assertNotIn('version:', args)
        self.assertNotIn('scheme:', args)
        self.assertIn('beta_description:' + description, args)
        self.assertFalse((self.root / 'should-not-exist').exists())


class ReleaseTests(Fixture):
    def setUp(self):
        super().setUp()
        for locale in ['en-US', 'zh-Hans']:
            path = self.target / 'fastlane/metadata' / locale
            path.mkdir(parents=True)
            for name in ['description', 'keywords', 'privacy_policy_url', 'release_notes', 'support_url', 'name']:
                (path / (name + '.txt')).write_text('Release content' if 'url' not in name else 'https://myapp.test/privacy')
        screenshots = self.target / 'fastlane/screenshots/en-US'
        screenshots.mkdir(parents=True)
        (screenshots / 'README.md').write_text('Screenshot instructions')
        self.env = dict(SCHEME='TargetApp', PROJECT='TargetApp.xcodeproj', APP_IDENTIFIER='com.test.app', FASTLANE_USER='fixture@test.invalid')

    def release(self, lane='release_existing', options=None, env=None):
        config = dict(root=str(self.target), lane=lane, options=options or {}, env=self.env if env is None else env)
        result = self.run_command(['ruby', '-e', RUBY_HARNESS, FASTFILE], input=json.dumps(config))
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def test_default_release_uploads_only_once_without_template_assets(self):
        result = self.release()
        self.assertIsNone(result['error'])
        self.assertEqual([x[0] for x in result['calls']], ['build_app', 'upload_to_testflight'])

    def test_metadata_after_pilot_skips_binary(self):
        result = self.release(options={'upload_metadata': True})
        self.assertIsNone(result['error'])
        self.assertEqual([x[0] for x in result['calls']], ['build_app', 'upload_to_testflight', 'deliver'])
        self.assertTrue(result['calls'][-1][1]['skip_binary_upload'])

    def test_missing_screenshots_fail_before_any_action(self):
        result = self.release(options={'upload_screenshots': True})
        self.assertIn('no screenshot files', result['error'])
        self.assertEqual(result['calls'], [])

    def test_empty_and_placeholder_metadata_fail_before_any_action(self):
        path = self.target / 'fastlane/metadata/en-US/description.txt'
        for value in ['', 'YourApp', 'https://example.com/privacy']:
            path.write_text(value)
            result = self.release(options={'upload_metadata': True})
            self.assertIn('placeholders', result['error'])
            self.assertEqual(result['calls'], [])

    def test_external_distribution_waits_and_rejects_conflicting_options(self):
        result = self.release(lane='testflight_only', options={'distribute_external': True, 'groups': 'External'})
        self.assertIsNone(result['error'])
        self.assertFalse(result['calls'][-1][1]['skip_waiting_for_build_processing'])
        result = self.release(options={'distribute_external': True, 'groups': 'External', 'skip_waiting_for_build_processing': True})
        self.assertIn('require', result['error'])
        self.assertEqual(result['calls'], [])

    def test_optional_empty_metadata_is_allowed(self):
        (self.target / 'fastlane/metadata/en-US/promotional_text.txt').write_text('')
        result = self.release(options={'upload_metadata': True})
        self.assertIsNone(result['error'])

    def test_empty_options_fall_back_and_do_not_change_version(self):
        result = self.release(options={'scheme': '', 'app_identifier': '', 'version': '', 'build_number': ''})
        self.assertIsNone(result['error'])
        self.assertEqual([x[0] for x in result['calls']], ['build_app', 'upload_to_testflight'])
        self.assertEqual(result['calls'][0][1]['scheme'], 'TargetApp')

    def test_no_build_inputs_required_for_metadata_or_existing_review(self):
        env = {key: value for key, value in self.env.items() if key not in ['SCHEME', 'PROJECT']}
        result = self.release(lane='metadata_only', env=env)
        self.assertIsNone(result['error'])
        self.assertEqual([x[0] for x in result['calls']], ['deliver'])
        result = self.release(lane='submit_review', options={'build_number': '17', 'version': '1.5'}, env=env)
        self.assertIsNone(result['error'])
        self.assertEqual(result['calls'][0][1]['build_number'], '17')
        self.assertTrue(result['calls'][0][1]['skip_binary_upload'])

    def test_review_uses_the_built_ipa_version(self):
        result = self.release(options={'submit_for_review': True})
        self.assertIsNone(result['error'])
        delivery = result['calls'][-1][1]
        self.assertEqual(delivery['build_number'], '42')
        self.assertEqual(delivery['app_version'], '2.0.0')
        self.assertTrue(delivery['skip_binary_upload'])
        pilot = next(args for name, args in result['calls'] if name == 'upload_to_testflight')
        self.assertFalse(pilot['skip_waiting_for_build_processing'])

    def test_direct_app_store_upload_has_one_binary_uploader(self):
        result = self.release(options={'upload_testflight': False, 'submit_for_review': True})
        self.assertIsNone(result['error'])
        self.assertNotIn('upload_to_testflight', [x[0] for x in result['calls']])
        self.assertFalse(result['calls'][-1][1]['skip_binary_upload'])
        self.assertNotIn('build_number', result['calls'][-1][1])

    def test_version_update_requires_explicit_project_with_workspace(self):
        (self.target / 'TargetApp.xcworkspace').mkdir()
        env = dict(self.env, WORKSPACE='TargetApp.xcworkspace')
        env.pop('PROJECT')
        result = self.release(options={'version': '2.0.0'}, env=env)
        self.assertIn('require project', result['error'])
        self.assertEqual(result['calls'], [])

    def test_external_distribution_rejects_disabled_testflight_upload(self):
        result = self.release(options={'upload_testflight': False, 'distribute_external': True, 'groups': 'External'})
        self.assertIn('requires upload_testflight', result['error'])
        self.assertEqual(result['calls'], [])

    def test_partial_credentials_and_bad_project_fail_before_any_action(self):
        result = self.release(env=dict(self.env, APP_STORE_KEY_ID='partial'))
        self.assertIn('incomplete', result['error'])
        self.assertEqual(result['calls'], [])
        result = self.release(env=dict(self.env, PROJECT='Missing.xcodeproj'))
        self.assertIn('does not exist', result['error'])
        self.assertEqual(result['calls'], [])

    def test_create_app_validates_assets_before_produce(self):
        result = self.release(lane='release_new', options={'create_app': True, 'app_name': 'App', 'sku': 'sku', 'upload_screenshots': True})
        self.assertIn('no screenshot files', result['error'])
        self.assertEqual(result['calls'], [])

    def test_version_updates_target_selected_project_and_workspace_build(self):
        (self.target / 'TargetApp.xcworkspace').mkdir()
        result = self.release(options={'workspace': 'TargetApp.xcworkspace', 'version': '1.2.0', 'build_number': '4'})
        self.assertIsNone(result['error'])
        self.assertEqual(result['calls'][0][1]['xcodeproj'], str(self.target / 'TargetApp.xcodeproj'))
        build = next(args for name, args in result['calls'] if name == 'build_app')
        self.assertIn('workspace', build)
        self.assertNotIn('project', build)


if __name__ == '__main__':
    unittest.main(verbosity=2)
