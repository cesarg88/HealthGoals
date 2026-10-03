#!/usr/bin/env python3
"""Repository-scoped API access with explicit identity; no credential fallback."""
import argparse
import base64
from contextlib import contextmanager
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request

class AccessError(Exception):
    pass

def run(args, **kwargs):
    result = subprocess.run(args, capture_output=True, **kwargs)
    if result.returncode:
        raise AccessError(f'{args[0]} failed (exit {result.returncode})')
    return result.stdout

def setting(name):
    value = run(['git', 'config', '--local', '--get', 'agentkit.github.' + name], env=clean_environment(), text=True).strip()
    if not value:
        raise AccessError('Missing local setting: ' + name)
    return value

class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise AccessError("GitHub redirects are not followed with credentials")

def request(token, method, path, body=None):
    req = urllib.request.Request('https://api.github.com' + path,
        data=json.dumps(body).encode() if body is not None else None,
        headers={'Authorization': 'Bearer ' + token, 'Accept': 'application/vnd.github+json',
                 'X-GitHub-Api-Version': '2022-11-28', 'Content-Type': 'application/json'}, method=method)
    try:
        with urllib.request.build_opener(NoRedirect()).open(req, timeout=30) as response:
            content = response.read()
            return json.loads(content) if content else None
    except urllib.error.HTTPError as error:
        raise AccessError(f'GitHub request failed (HTTP {error.code})') from None
    except urllib.error.URLError:
        raise AccessError('GitHub connection failed') from None

def scoped_path(repository, path):
    prefix = '/repos/' + repository
    if not (path == prefix or path.startswith(prefix + '/') or path.startswith(prefix + '?')):
        raise AccessError('API path must belong to the configured repository')
    if any(part in path for part in ('..', '%', '\\', '#')):
        raise AccessError('Unsafe API path')
    return path

def jwt(client_id, pem_path):
    key = Path(pem_path).expanduser().resolve()
    root = Path(run(['git', 'rev-parse', '--show-toplevel'], env=clean_environment(), text=True).strip()).resolve()
    if key.is_relative_to(root) or not key.is_file() or stat.S_IMODE(key.stat().st_mode) != 0o600:
        raise AccessError('App key must be outside the checkout with permissions 0600')
    def encode(value):
        return base64.urlsafe_b64encode(value).rstrip(b'=')
    now = int(time.time())
    message = encode(b'{"alg":"RS256","typ":"JWT"}') + b'.' + encode(json.dumps(
        {'iat': now - 60, 'exp': now + 540, 'iss': client_id}).encode())
    signature = run(['openssl', 'dgst', '-sha256', '-sign', str(key)], input=message)
    return (message + b'.' + encode(signature)).decode()

def authenticate(repository, permission, level, extra_permissions=None):
    mode, actor = setting('mode'), setting('actor')
    if mode == 'personal':
        # Only an explicitly supplied, process-local token. Never consult global gh.
        token = os.environ.get('AGENTKIT_GITHUB_TOKEN')
        if not token:
            raise AccessError('Personal mode requires AGENTKIT_GITHUB_TOKEN in the process environment')
        if request(token, 'GET', '/user')['login'] != actor:
            raise AccessError('Personal account does not match configured actor')
        return token, actor
    if mode != 'app':
        raise AccessError('Authentication mode must be explicitly app or personal')
    app_jwt = jwt(setting('clientId'), setting('pemPath'))
    app = request(app_jwt, 'GET', '/app')
    if str(app['id']) != setting('appId') or app['slug'] + '[bot]' != actor:
        raise AccessError('App identity mismatch')
    installation = request(app_jwt, 'GET', '/repos/' + repository + '/installation')
    if str(installation['id']) != setting('installationId'):
        raise AccessError('App installation mismatch')
    permissions = {permission: level, **(extra_permissions or {})}
    result = request(app_jwt, 'POST', '/app/installations/' + str(installation['id']) + '/access_tokens',
        {'repositories': [repository.split('/')[1]], 'permissions': permissions})
    repos = result.get('repositories', [])
    if len(repos) != 1 or repos[0]['full_name'] != repository:
        raise AccessError('Installation token scope mismatch')
    for name, required in permissions.items():
        if result.get('permissions', {}).get(name) != required:
            raise AccessError('Installation token permission mismatch')
    return result['token'], actor

def clean_environment():
    env = os.environ.copy()
    for key in list(env):
        if key.startswith('GIT_') or key in ('GH_TOKEN', 'GITHUB_TOKEN', 'AGENTKIT_GITHUB_TOKEN', 'SSH_ASKPASS') or key.lower() in ('http_proxy', 'https_proxy', 'all_proxy', 'no_proxy'):
            env.pop(key)
    return env


def git_environment(token, url):
    env = clean_environment()
    auth = base64.b64encode(('x-access-token:' + token).encode()).decode()
    config = [
        ('credential.helper', ''), ('core.askPass', ''), ('core.hooksPath', os.devnull),
        ('http.followRedirects', 'false'), ('http.proxy', ''), ('http.extraHeader', ''),
        ('http.' + url + '.extraHeader', 'Authorization: Basic ' + auth),
    ]
    env.update({'GIT_CONFIG_NOSYSTEM': '1', 'GIT_CONFIG_SYSTEM': os.devnull,
                'GIT_CONFIG_GLOBAL': os.devnull, 'GIT_CONFIG_COUNT': str(len(config)),
                'GIT_ASKPASS': '', 'SSH_ASKPASS': '', 'GIT_TERMINAL_PROMPT': '0',
                'GIT_ALLOW_PROTOCOL': 'https'})
    for index, (key, value) in enumerate(config):
        env['GIT_CONFIG_KEY_' + str(index)] = key
        env['GIT_CONFIG_VALUE_' + str(index)] = value
    return env


@contextmanager
def git_transport(token, url, objects, object_format):
    # A separate bare repository prevents source-local config (including URL rewrites,
    # headers, includes, remotes and hooks) from participating in authenticated Git.
    if object_format not in ('sha1', 'sha256') or '\n' in str(objects) or '\r' in str(objects):
        raise AccessError('Unsupported source object store')
    with tempfile.TemporaryDirectory(prefix='agentkit-git-') as directory:
        bare = Path(directory) / 'transport.git'
        env = git_environment(token, url)
        init_env = clean_environment()
        init_env.update({'GIT_CONFIG_NOSYSTEM': '1', 'GIT_CONFIG_SYSTEM': os.devnull,
                         'GIT_CONFIG_GLOBAL': os.devnull})
        # No token is supplied to initialization or written into its config.
        run(['git', 'init', '--bare', '--template=', '--object-format=' + object_format, str(bare)],
            cwd=directory, env=init_env, text=True)
        (bare / 'objects/info/alternates').write_text(str(objects) + '\n')
        yield ['git', '--git-dir=' + str(bare)], env


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    api = sub.add_parser('api')
    api.add_argument('method', choices=['GET', 'POST', 'PATCH', 'PUT', 'DELETE'])
    api.add_argument('path')
    api.add_argument('--body-file', type=Path)
    api.add_argument('--permission', choices=['contents', 'issues', 'pull_requests', 'actions', 'administration'], required=True)
    push = sub.add_parser('push')
    push.add_argument('branch')
    push.add_argument('--workflows', action='store_true', help='Request workflows:write in App mode when changing workflow files')
    args = parser.parse_args()
    repository = setting('repository')
    if not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', repository):
        raise AccessError('Invalid configured repository')
    if args.command == 'api':
        path = scoped_path(repository, args.path)
        token, _ = authenticate(repository, args.permission, 'read' if args.method == 'GET' else 'write')
        body = json.loads(args.body_file.read_text()) if args.body_file else None
        result = request(token, args.method, path, body)
        # Resource user fields describe authorship, not the actor performing an update.
        # authenticate() verifies the credential identity before any repository write.
        print(json.dumps(result, indent=2))
    else:
        source_env = clean_environment()
        run(['git', 'check-ref-format', '--branch', args.branch], env=source_env, text=True)
        current = run(['git', 'branch', '--show-current'], env=source_env, text=True).strip()
        if current != args.branch or current == setting('integrationBranch'):
            raise AccessError('Push requires current task branch, not integration branch')
        expected = 'https://github.com/' + repository + '.git'
        # Validate configured origin as metadata, not as the authenticated destination.
        origin = run(['git', 'config', '--local', '--get-all', 'remote.origin.url'], env=source_env, text=True).splitlines()
        if origin != [expected]:
            raise AccessError('Origin must be the configured HTTPS repository')
        if run(['git', 'config', '--local', '--get', 'user.name'], env=source_env, text=True).strip() != setting('actor'):
            raise AccessError('Local commit author mismatch')
        if run(['git', 'config', '--local', '--get', 'user.email'], env=source_env, text=True).strip() != setting('actorEmail'):
            raise AccessError('Local commit email mismatch')
        if run(['git', 'rev-parse', '--is-shallow-repository'], env=source_env, text=True).strip() != 'false':
            raise AccessError('Push requires a full clone with local history')
        head = run(['git', 'rev-parse', '--verify', 'HEAD^{commit}'], env=source_env, text=True).strip()
        objects = Path(run(['git', 'rev-parse', '--git-path', 'objects'], env=source_env, text=True).strip()).resolve()
        object_format = run(['git', 'rev-parse', '--show-object-format'], env=source_env, text=True).strip()
        token, _ = authenticate(repository, 'contents', 'write', {'workflows': 'write'} if args.workflows else None)
        ref = 'refs/heads/' + args.branch
        with git_transport(token, expected, objects, object_format) as (git, env):
            run(git + ['push', '--', expected, head + ':' + ref], env=env, text=True)
            remote = run(git + ['ls-remote', '--refs', '--', expected, ref], env=env, text=True).splitlines()
        if remote != [head + '\t' + ref]:
            raise AccessError('Remote head mismatch')
        print(head)

if __name__ == '__main__':
    try:
        main()
    except (AccessError, ValueError, OSError) as error:
        print(str(error) if isinstance(error, AccessError) else type(error).__name__, file=sys.stderr)
        sys.exit(1)
