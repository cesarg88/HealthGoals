import importlib.util
import io
import base64
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import threading
import json
import sys
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import call, patch

spec = importlib.util.spec_from_file_location('agent_github', Path(__file__).resolve().parents[1] / 'tools/agent-github/agent_github.py')
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)

class AuthenticationTests(unittest.TestCase):
    def test_repository_scope_rejects_other_repositories_and_traversal(self):
        for path in ('/user', '/repos/owner/other', '/repos/owner/repo2', '/repos/owner/repo/../other', '/repos/owner/repo/%2e%2e'):
            with self.subTest(path=path), self.assertRaises(helper.AccessError):
                helper.scoped_path('owner/repo', path)
        self.assertEqual(helper.scoped_path('owner/repo', '/repos/owner/repo/issues?state=open'), '/repos/owner/repo/issues?state=open')

    def test_no_personal_fallback_when_app_fails(self):
        settings = {'mode': 'app', 'actor': 'test[bot]', 'clientId': 'client', 'pemPath': '/missing'}
        with patch.object(helper, 'setting', side_effect=settings.__getitem__), patch.object(helper, 'jwt', side_effect=helper.AccessError('key missing')), patch.object(helper, 'request') as api, patch.dict(os.environ, {'AGENTKIT_GITHUB_TOKEN': 'personal'}):
            with self.assertRaises(helper.AccessError):
                helper.authenticate('owner/repo', 'contents', 'read')
            api.assert_not_called()

    def test_personal_identity_mismatch(self):
        settings = {'mode': 'personal', 'actor': 'authorized'}
        with patch.object(helper, 'setting', side_effect=settings.__getitem__), patch.object(helper, 'request', return_value={'login': 'other'}), patch.dict(os.environ, {'AGENTKIT_GITHUB_TOKEN': 'token'}):
            with self.assertRaises(helper.AccessError):
                helper.authenticate('owner/repo', 'contents', 'read')

    def test_personal_requires_explicit_token(self):
        settings = {'mode': 'personal', 'actor': 'authorized'}
        with patch.object(helper, 'setting', side_effect=settings.__getitem__), patch.dict(os.environ, {}, clear=True), patch.object(helper, 'run') as child:
            with self.assertRaises(helper.AccessError):
                helper.authenticate('owner/repo', 'contents', 'read')
            child.assert_not_called()

    def test_patch_other_authors_issue_and_pr_succeeds_after_identity_preflight(self):
        settings = {'repository': 'owner/repo', 'mode': 'personal', 'actor': 'authorized'}
        for resource, permission in (('issues', 'issues'), ('pulls', 'pull_requests')):
            path = '/repos/owner/repo/' + resource + '/17'
            response = {'number': 17, 'user': {'login': 'original-author'}, 'title': 'Updated'}
            with self.subTest(resource=resource), tempfile.TemporaryDirectory() as directory:
                body_file = Path(directory) / 'body.json'
                body_file.write_text(json.dumps({'title': 'Updated'}))
                argv = ['agent_github.py', 'api', 'PATCH', path, '--permission', permission, '--body-file', str(body_file)]
                output = io.StringIO()
                with patch.object(helper, 'setting', side_effect=settings.__getitem__), patch.object(helper, 'request', side_effect=[{'login': 'authorized'}, response]) as api, patch.dict(os.environ, {'AGENTKIT_GITHUB_TOKEN': 'token'}), patch.object(sys, 'argv', argv), patch('sys.stdout', output):
                    helper.main()
                self.assertEqual(json.loads(output.getvalue()), response)
                self.assertEqual(api.call_args_list, [call('token', 'GET', '/user'), call('token', 'PATCH', path, {'title': 'Updated'})])

    def test_patch_identity_mismatch_stops_before_issue_or_pr_write(self):
        settings = {'repository': 'owner/repo', 'mode': 'personal', 'actor': 'authorized'}
        for resource, permission in (('issues', 'issues'), ('pulls', 'pull_requests')):
            with self.subTest(resource=resource):
                argv = ['agent_github.py', 'api', 'PATCH', '/repos/owner/repo/' + resource + '/17', '--permission', permission]
                with patch.object(helper, 'setting', side_effect=settings.__getitem__), patch.object(helper, 'request', return_value={'login': 'other'}) as api, patch.dict(os.environ, {'AGENTKIT_GITHUB_TOKEN': 'token'}), patch.object(sys, 'argv', argv):
                    with self.assertRaises(helper.AccessError):
                        helper.main()
                    self.assertEqual(api.call_args_list, [call('token', 'GET', '/user')])

    def test_app_mints_only_requested_repository_and_permission(self):
        settings = {'mode': 'app', 'actor': 'test[bot]', 'clientId': 'client', 'pemPath': '/key', 'appId': '42', 'installationId': '7'}
        responses = [{'id': 42, 'slug': 'test'}, {'id': 7}, {'token': 'installation', 'repositories': [{'full_name': 'owner/repo'}], 'permissions': {'issues': 'write'}}]
        with patch.object(helper, 'setting', side_effect=settings.__getitem__), patch.object(helper, 'jwt', return_value='jwt'), patch.object(helper, 'request', side_effect=responses) as api:
            self.assertEqual(helper.authenticate('owner/repo', 'issues', 'write'), ('installation', 'test[bot]'))
            self.assertEqual(api.call_args.args[3], {'repositories': ['repo'], 'permissions': {'issues': 'write'}})

    def test_app_rejects_broader_token_scope(self):
        settings = {'mode': 'app', 'actor': 'test[bot]', 'clientId': 'client', 'pemPath': '/key', 'appId': '42', 'installationId': '7'}
        responses = [{'id': 42, 'slug': 'test'}, {'id': 7}, {'token': 'installation', 'repositories': [{'full_name': 'owner/repo'}, {'full_name': 'owner/other'}], 'permissions': {'contents': 'read'}}]
        with patch.object(helper, 'setting', side_effect=settings.__getitem__), patch.object(helper, 'jwt', return_value='jwt'), patch.object(helper, 'request', side_effect=responses):
            with self.assertRaises(helper.AccessError):
                helper.authenticate('owner/repo', 'contents', 'read')

    def test_workflow_push_requires_both_grants(self):
        settings = {'mode': 'app', 'actor': 'test[bot]', 'clientId': 'client', 'pemPath': '/key', 'appId': '42', 'installationId': '7'}
        responses = [{'id': 42, 'slug': 'test'}, {'id': 7}, {'token': 'installation', 'repositories': [{'full_name': 'owner/repo'}], 'permissions': {'contents': 'write'}}]
        with patch.object(helper, 'setting', side_effect=settings.__getitem__), patch.object(helper, 'jwt', return_value='jwt'), patch.object(helper, 'request', side_effect=responses) as api:
            with self.assertRaises(helper.AccessError):
                helper.authenticate('owner/repo', 'contents', 'write', {'workflows': 'write'})
            self.assertEqual(api.call_args.args[3]['permissions'], {'contents': 'write', 'workflows': 'write'})

    def test_git_credentials_are_process_local_and_inherited_tokens_removed(self):
        with patch.dict(os.environ, {'GITHUB_TOKEN': 'old', 'GIT_CONFIG_COUNT': '99', 'AGENTKIT_GITHUB_TOKEN': 'old'}):
            env = helper.git_environment('new', 'https://github.com/owner/repo.git')
            self.assertNotIn('GITHUB_TOKEN', env)
            self.assertNotIn('AGENTKIT_GITHUB_TOKEN', env)
            self.assertEqual(env['GIT_CONFIG_COUNT'], '7')
            self.assertEqual(env['GIT_CONFIG_VALUE_0'], '')
            self.assertEqual(os.environ['GITHUB_TOKEN'], 'old')

    def test_real_git_does_not_run_configured_askpass_on_credential_challenge(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            checkout = root / 'checkout'
            checkout.mkdir()
            global_config = root / 'global.gitconfig'
            marker = root / 'askpass-invoked'
            program = root / 'askpass'
            program.write_text('#!/bin/sh\nprintf attempted > "' + str(marker) + '"\nexit 1\n')
            program.chmod(0o700)
            isolated = os.environ.copy()
            for key in list(isolated):
                if key.startswith('GIT_CONFIG_') or key in ('GIT_ASKPASS', 'SSH_ASKPASS'):
                    isolated.pop(key)
            isolated.update({'GIT_CONFIG_GLOBAL': str(global_config), 'GIT_CONFIG_NOSYSTEM': '1', 'GIT_TERMINAL_PROMPT': '0'})
            subprocess.run(['git', 'init', str(checkout)], env=isolated, check=True, capture_output=True)
            subprocess.run(['git', 'config', '--global', 'core.askPass', str(program)], env=isolated, check=True)
            subprocess.run(['git', 'config', '--local', 'core.askPass', str(program)], cwd=checkout, env=isolated, check=True)
            credential_query = 'protocol=https\nhost=example.invalid\n\n'
            # Establish that Git consults the configured program despite terminal prompting being disabled.
            control = subprocess.run(['git', 'credential', 'fill'], cwd=checkout, env=isolated, input=credential_query, text=True, capture_output=True, timeout=5)
            self.assertNotEqual(control.returncode, 0)
            self.assertTrue(marker.exists())
            marker.unlink()
            with patch.dict(os.environ, isolated, clear=True):
                parent = os.environ.copy()
                protected = helper.git_environment('explicit-token', 'https://github.com/owner/repo.git')
                self.assertEqual(dict(os.environ), parent)
            # Restore only test-owned global/system isolation after the helper removes inherited config.
            protected.update({'GIT_CONFIG_GLOBAL': str(global_config), 'GIT_CONFIG_NOSYSTEM': '1'})
            result = subprocess.run(['git', 'credential', 'fill'], cwd=checkout, env=protected, input=credential_query, text=True, capture_output=True, timeout=5)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(marker.exists())
            self.assertEqual(result.stdout, '')

    def test_isolated_transport_ignores_source_credentials_destinations_and_redirects(self):
        observed = []
        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                observed.append((self.path, self.headers.get_all('Authorization')))
                self.send_response(302 if self.path.startswith('/redirect/') else 401)
                if self.path.startswith('/redirect/'):
                    self.send_header('Location', '/forbidden/info/refs')
                self.end_headers()
            def log_message(self, *args):
                pass
        server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            with tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                source = root / 'source'
                source.mkdir()
                global_config = root / 'global.gitconfig'
                marker = root / 'unexpected-askpass'
                askpass = root / 'askpass'
                askpass.write_text('#!/bin/sh\nprintf attempted > "' + str(marker) + '"\nexit 1\n')
                askpass.chmod(0o700)
                url = 'http://127.0.0.1:' + str(server.server_port) + '/allowed/repo.git'
                wrong = 'http://127.0.0.1:' + str(server.server_port) + '/forbidden/repo.git'
                isolated = helper.clean_environment()
                isolated.update({'GIT_CONFIG_NOSYSTEM': '1', 'GIT_CONFIG_GLOBAL': str(global_config)})
                subprocess.run(['git', 'init', str(source)], env=isolated, check=True, capture_output=True)
                def config(scope, key, value, add=False):
                    subprocess.run(['git', 'config', scope] + (['--add'] if add else []) + [key, value], cwd=source, env=isolated, check=True)
                for scope in ('--global', '--local'):
                    config(scope, 'http.extraHeader', 'Authorization: WRONG', add=True)
                    config(scope, 'http.' + url + '.extraHeader', 'Authorization: SCOPED-WRONG', add=True)
                    config(scope, 'url.' + wrong + '.insteadOf', url)
                    config(scope, 'url.' + wrong + '.pushInsteadOf', url)
                    config(scope, 'core.askPass', str(askpass))
                    config(scope, 'http.proxy', 'http://127.0.0.1:1')
                config('--local', 'remote.origin.url', url)
                config('--local', 'remote.origin.pushurl', wrong, add=True)
                config('--local', 'remote.origin.pushurl', wrong + '/second', add=True)
                objects = source / '.git/objects'
                inherited = dict(isolated, GIT_ASKPASS=str(askpass), HTTPS_PROXY='http://127.0.0.1:1', GIT_TRACE='1', GIT_CONFIG_COUNT='1', GIT_CONFIG_KEY_0='http.extraHeader', GIT_CONFIG_VALUE_0='Authorization: ENV-WRONG')
                before = os.environ.copy()
                for destination in (url, url.replace('/allowed/', '/redirect/')):
                    with patch.dict(os.environ, inherited, clear=True), helper.git_transport('fake-token', destination, objects, 'sha1') as (git, env):
                        # Tests allow loopback HTTP; production allows HTTPS only.
                        env['GIT_ALLOW_PROTOCOL'] = 'http'
                        self.assertNotIn('HTTPS_PROXY', env)
                        self.assertNotIn('GIT_TRACE', env)
                        rewritten = subprocess.run(git + ['ls-remote', '--get-url', destination], env=env, capture_output=True, text=True, check=True)
                        self.assertEqual(rewritten.stdout.strip(), destination)
                        result = subprocess.run(git + ['ls-remote', '--refs', '--', destination], env=env, capture_output=True, text=True, timeout=5)
                        self.assertNotEqual(result.returncode, 0)
                        self.assertFalse(marker.exists())
                self.assertEqual(dict(os.environ), before)
                auth = 'Basic ' + base64.b64encode(b'x-access-token:fake-token').decode()
                self.assertEqual(observed, [('/allowed/repo.git/info/refs?service=git-upload-pack', [auth]), ('/redirect/repo.git/info/refs?service=git-upload-pack', [auth])])
        finally:
            server.shutdown()
            server.server_close()
            thread.join()

    def test_real_push_uses_isolated_destination_and_source_object_store(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source, destination, wrong = (root / name for name in ('source', 'destination.git', 'wrong.git'))
            isolated = helper.clean_environment()
            isolated.update({'GIT_CONFIG_NOSYSTEM': '1', 'GIT_CONFIG_GLOBAL': os.devnull})
            for path in (destination, wrong):
                subprocess.run(['git', 'init', '--bare', '--template=', str(path)], env=isolated, capture_output=True, check=True)
            subprocess.run(['git', 'init', '--template=', str(source)], env=isolated, capture_output=True, check=True)
            subprocess.run(['git', '-c', 'user.name=test', '-c', 'user.email=test@example.invalid', 'commit', '--allow-empty', '-m', 'Source objects'], cwd=source, env=isolated, capture_output=True, check=True)
            head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=source, env=isolated, text=True).strip()
            url = destination.as_uri()
            subprocess.run(['git', 'config', 'remote.origin.url', url], cwd=source, env=isolated, check=True)
            subprocess.run(['git', 'config', '--add', 'remote.origin.pushurl', wrong.as_uri()], cwd=source, env=isolated, check=True)
            subprocess.run(['git', 'config', '--add', 'remote.origin.pushurl', wrong.as_uri() + '/other'], cwd=source, env=isolated, check=True)
            subprocess.run(['git', 'config', 'url.' + wrong.as_uri() + '.insteadOf', url], cwd=source, env=isolated, check=True)
            subprocess.run(['git', 'config', 'url.' + wrong.as_uri() + '.pushInsteadOf', url], cwd=source, env=isolated, check=True)
            ref = 'refs/heads/feature/task'
            with patch.dict(os.environ, isolated, clear=True), helper.git_transport('fake-token', url, source / '.git/objects', 'sha1') as (git, env):
                # Production only allows HTTPS; this offline test uses local bare remotes.
                env['GIT_ALLOW_PROTOCOL'] = 'file'
                subprocess.run(git + ['push', '--', url, head + ':' + ref], env=env, cwd=source, capture_output=True, check=True)
                actual = subprocess.check_output(git + ['ls-remote', '--refs', '--', url, ref], env=env, cwd=source, text=True).strip()
                self.assertEqual(actual, head + '\t' + ref)
            self.assertEqual(subprocess.check_output(['git', '--git-dir=' + str(wrong), 'for-each-ref'], env=isolated, text=True), '')

    def test_push_cli_snapshots_worktree_head_and_verifies_exact_ref(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source, worktree, destination, wrong = (root / name for name in ('source', 'worktree', 'destination.git', 'wrong.git'))
            isolated = helper.clean_environment()
            isolated.update({'GIT_CONFIG_NOSYSTEM': '1', 'GIT_CONFIG_GLOBAL': os.devnull})
            for path in (destination, wrong):
                subprocess.run(['git', 'init', '--bare', '--template=', str(path)], env=isolated, capture_output=True, check=True)
            subprocess.run(['git', 'init', '--template=', str(source)], env=isolated, capture_output=True, check=True)
            def git(*args, cwd=source):
                return subprocess.run(['git', *args], cwd=cwd, env=isolated, capture_output=True, text=True, check=True).stdout.strip()
            for key, value in {
                'user.name': 'authorized', 'user.email': 'authorized@example.invalid',
                'agentkit.github.repository': 'owner/repo', 'agentkit.github.actor': 'authorized',
                'agentkit.github.actorEmail': 'authorized@example.invalid', 'agentkit.github.integrationBranch': 'develop',
                'remote.origin.url': 'https://github.com/owner/repo.git',
                'remote.origin.pushurl': wrong.as_uri(),
            }.items():
                git('config', '--local', key, value)
            git('commit', '--allow-empty', '-m', 'Baseline')
            git('worktree', 'add', '-b', 'feature/task', str(worktree))
            head = git('rev-parse', 'HEAD', cwd=worktree)
            expected = 'https://github.com/owner/repo.git'
            ref = 'refs/heads/feature/task'
            calls = []
            original_run = helper.run
            def transport_run(args, **kwargs):
                if len(args) > 2 and args[1].startswith('--git-dir=') and args[2] in ('push', 'ls-remote'):
                    calls.append(list(args[2:]))
                    self.assertIn(expected, args)
                    args = [destination.as_uri() if value == expected else value for value in args]
                    kwargs['env'] = dict(kwargs['env'], GIT_ALLOW_PROTOCOL='file')
                return original_run(args, **kwargs)
            def authorize(*args):
                # HEAD may advance while authentication runs; send and verify the earlier snapshot.
                git('commit', '--allow-empty', '-m', 'Later commit', cwd=worktree)
                return 'fake-token', 'authorized'
            previous = Path.cwd()
            output = io.StringIO()
            try:
                os.chdir(worktree)
                with patch.object(helper, 'run', side_effect=transport_run), patch.object(helper, 'authenticate', side_effect=authorize), patch.object(sys, 'argv', ['agent_github.py', 'push', 'feature/task']), patch('sys.stdout', output):
                    helper.main()
            finally:
                os.chdir(previous)
            self.assertEqual(calls, [['push', '--', expected, head + ':' + ref], ['ls-remote', '--refs', '--', expected, ref]])
            self.assertEqual(output.getvalue().strip(), head)
            self.assertNotEqual(git('rev-parse', 'HEAD', cwd=worktree), head)
            self.assertEqual(git('--git-dir=' + str(destination), 'rev-parse', ref), head)
            self.assertEqual(git('--git-dir=' + str(wrong), 'for-each-ref'), '')

    def test_redirects_do_not_forward_credentials(self):
        with self.assertRaises(helper.AccessError):
            helper.NoRedirect().redirect_request(None, None, 302, "redirect", {}, "https://other.example")

    def test_child_error_does_not_expose_stderr(self):
        result = subprocess.CompletedProcess(['git'], 1, b'', b'SECRET')
        with patch.object(subprocess, 'run', return_value=result):
            with self.assertRaises(helper.AccessError) as caught:
                helper.run(['git'])
            self.assertNotIn('SECRET', str(caught.exception))

    def test_jwt_is_signed_and_has_bounded_expiry(self):
        import base64
        import json
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            checkout = root / 'checkout'
            checkout.mkdir()
            key = root / 'app.pem'
            subprocess.run(['openssl', 'genrsa', '-out', str(key), '2048'], check=True, capture_output=True)
            key.chmod(0o600)
            original = helper.run
            def execute(args, **kwargs):
                return str(checkout) if args[:2] == ['git', 'rev-parse'] else original(args, **kwargs)
            with patch.object(helper, 'run', side_effect=execute), patch.object(helper.time, 'time', return_value=1000):
                token = helper.jwt('client', str(key))
            header, payload, signature = token.split('.')
            claims = json.loads(base64.urlsafe_b64decode(payload + '=' * (-len(payload) % 4)))
            self.assertEqual(claims, {'iat': 940, 'exp': 1540, 'iss': 'client'})
            signed = root / 'signature'
            signed.write_bytes(base64.urlsafe_b64decode(signature + '=' * (-len(signature) % 4)))
            public = root / 'public.pem'
            public.write_bytes(subprocess.run(['openssl', 'rsa', '-in', str(key), '-pubout'], check=True, capture_output=True).stdout)
            result = subprocess.run(['openssl', 'dgst', '-sha256', '-verify', str(public), '-signature', str(signed)], input=(header + '.' + payload).encode(), capture_output=True)
            self.assertEqual(result.returncode, 0)

if __name__ == '__main__':
    unittest.main()
