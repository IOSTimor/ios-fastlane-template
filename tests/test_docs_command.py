"""Verify documentation routing without opening a real browser or downloading code."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

REPO=Path(__file__).resolve().parents[1]
URL='https://github.com/IOSTimor/ios-fastlane-template/blob/main/docs/user_guide.md'

class DocsCommandTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='iosipa-docs-')
        self.addCleanup(self.temp.cleanup)
        self.root=Path(self.temp.name)
        self.bin=self.root/'bin';self.bin.mkdir()
        self.capture=self.root/'opened-url'
        self.bash=shutil.which('bash')
        (self.bin/'basename').symlink_to(shutil.which('basename'))
        self.opener(self.bin/'open')
        self.env=dict(os.environ,PATH=str(self.bin),SCRIPT_NAME_OVERRIDE='iosipa',OPENED_URL=str(self.capture),LOCAL_ARCHIVE_PATH='/must-not-read',ARCHIVE_URL='https://must-not-download.invalid')

    def opener(self,path):
        path.write_text('#!'+sys.executable+'\nimport os,sys\nfrom pathlib import Path\nPath(os.environ["OPENED_URL"]).write_text(sys.argv[1])\nsys.exit(1 if os.environ.get("FAIL_OPEN") else 0)\n')
        path.chmod(0o755)

    def run_docs(self,*flags,env=None):
        return subprocess.run([self.bash,str(REPO/'scripts/install.sh'),'docs',*flags],cwd=self.root,env=env or self.env,text=True,capture_output=True,timeout=15)

    def test_opens_user_guide_without_project_ruby_xcode_or_download(self):
        result=self.run_docs()
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(self.capture.read_text(),URL)
        self.assertIn(URL,result.stdout)
        self.assertFalse((self.root/'fastlane').exists())

    def test_url_only_never_opens_browser(self):
        result=self.run_docs('--url')
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(result.stdout.strip(),URL)
        self.assertFalse(self.capture.exists())

    def test_help_and_legacy_name(self):
        result=self.run_docs('--help')
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn('Usage: iosipa docs',result.stdout)
        env=dict(self.env,SCRIPT_NAME_OVERRIDE='ios-fastlane-template')
        result=self.run_docs('--help',env=env)
        self.assertIn('Usage: ios-fastlane-template docs',result.stdout)
        self.assertFalse(self.capture.exists())

    def test_xdg_opener_fallback(self):
        (self.bin/'open').rename(self.bin/'xdg-open')
        result=self.run_docs()
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(self.capture.read_text(),URL)

    def test_missing_or_failed_opener_reports_url(self):
        result=self.run_docs(env=dict(self.env,FAIL_OPEN='1'))
        self.assertNotEqual(result.returncode,0)
        self.assertIn(URL,result.stdout)
        self.capture.unlink();(self.bin/'open').unlink()
        result=self.run_docs()
        self.assertNotEqual(result.returncode,0)
        self.assertIn(URL,result.stdout)
        self.assertIn('--url',result.stderr)

    def test_invalid_arguments_do_not_open_browser(self):
        for flags in [('--unknown',),('--url','extra'),('https://other.invalid',)]:
            result=self.run_docs(*flags)
            self.assertNotEqual(result.returncode,0)
            self.assertFalse(self.capture.exists())

if __name__=='__main__':unittest.main(verbosity=2)
