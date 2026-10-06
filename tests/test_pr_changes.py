"""Exercise CI classification with real Git histories, without GitHub access."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts/classify-pr-changes.py'


class PRChangesTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.env = {k: v for k, v in os.environ.items() if not k.startswith('GIT_')}
        self.env.update(GIT_CONFIG_NOSYSTEM='1', GIT_CONFIG_GLOBAL=os.devnull)
        self.git('init', '--template=')
        self.git('config', 'user.name', 'CI test')
        self.git('config', 'user.email', 'ci@example.invalid')
        self.git('config', 'core.hooksPath', os.devnull)
        self.write('App.swift', 'original\n')
        self.write('README.md', 'original\n')
        self.base = self.commit()

    def git(self, *args):
        return subprocess.check_output(['git', *args], cwd=self.root, env=self.env,
                                       stderr=subprocess.DEVNULL, text=True).strip()

    def write(self, name, content):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)

    def commit(self):
        self.git('add', '-A')
        self.git('commit', '-m', 'fixture')
        return self.git('rev-parse', 'HEAD')

    def classify(self, base=None, head=None):
        return subprocess.check_output(
            ['python3', str(SCRIPT), base or self.base, head or self.git('rev-parse', 'HEAD')],
            cwd=self.root, env=self.env, stderr=subprocess.DEVNULL, text=True,
        ).strip()

    def test_markdown_add_edit_delete_and_rename(self):
        self.write('README.md', 'edited\n')
        self.write('docs/space and\nnewline.md', 'new\n')
        self.commit()
        self.assertEqual(self.classify(), 'docs_only=true')
        self.git('mv', 'README.md', 'guide.md')
        self.commit()
        self.assertEqual(self.classify(), 'docs_only=true')
        self.git('rm', 'guide.md')
        self.commit()
        self.assertEqual(self.classify(), 'docs_only=true')

    def test_earlier_code_commit_is_not_hidden_by_last_documentation_commit(self):
        self.write('App.swift', 'changed code\n')
        self.commit()
        self.write('README.md', 'latest docs\n')
        self.commit()
        self.assertEqual(self.classify(), 'docs_only=false')

    def test_workflow_and_build_changes_require_ios(self):
        for name in ['.github/workflows/ios.yml', 'App.xcodeproj/project.pbxproj', 'Makefile']:
            with self.subTest(name=name):
                base = self.git('rev-parse', 'HEAD')
                self.write(name, 'changed\n')
                self.commit()
                self.assertEqual(self.classify(base=base), 'docs_only=false')

    def test_code_renamed_to_markdown_requires_ios(self):
        self.git('mv', 'App.swift', 'App.md')
        self.commit()
        self.assertEqual(self.classify(), 'docs_only=false')

    def test_empty_or_unavailable_diff_requires_ios(self):
        self.assertEqual(self.classify(), 'docs_only=false')
        self.assertEqual(self.classify(base='0' * 40), 'docs_only=false')
        self.assertEqual(self.classify(base='--invalid'), 'docs_only=false')

    def test_unrelated_base_branch_changes_are_excluded(self):
        self.write('README.md', 'PR docs\n')
        head = self.commit()
        self.git('checkout', '--detach', self.base)
        self.write('App.swift', 'base branch code\n')
        updated_base = self.commit()
        self.assertEqual(self.classify(base=updated_base, head=head), 'docs_only=true')


if __name__ == '__main__':
    unittest.main()
