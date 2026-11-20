#!/usr/bin/env python3
"""Exercise Sparkle download verification, replacement, and relaunch in disposable apps.
Requires the release signing key in the local Keychain; never touches the installed app.
"""
import functools
import http.server
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile
import threading
import time
import uuid

ROOT = Path(__file__).resolve().parents[2]
SPARKLE = ROOT / '.dependencies/Sparkle-2.10.1'

def run(*args):
    subprocess.run([str(a) for a in args], check=True)

with tempfile.TemporaryDirectory(prefix='minimized-updater-') as folder:
    base = Path(folder)
    served = base / 'served'
    served.mkdir()
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(served))
    server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    prefix = f'http://127.0.0.1:{server.server_port}/'
    identifier = 'com.madsfeiring.minimizedwindows.updater-test.' + uuid.uuid4().hex
    log = base / 'events.log'
    log.touch()
    binary = base / 'UpdaterFixture'
    run('clang', '-fobjc-arc', ROOT / 'Tests/Updater/main.m', '-F', SPARKLE,
        '-framework', 'Cocoa', '-framework', 'Sparkle', '-Wl,-rpath,@executable_path/../Frameworks', '-o', binary)
    with (ROOT / 'Sources/Info.plist').open('rb') as f:
        public_key = plistlib.load(f)['SUPublicEDKey']

    def app_at(parent, version, cancel=False):
        app = parent / 'Updater Fixture.app'
        contents = app / 'Contents'
        (contents / 'MacOS').mkdir(parents=True)
        shutil.copy2(binary, contents / 'MacOS/UpdaterFixture')
        run('ditto', SPARKLE / 'Sparkle.framework', contents / 'Frameworks/Sparkle.framework')
        info = dict(CFBundleIdentifier=identifier, CFBundleName='Updater Fixture',
                    CFBundleExecutable='UpdaterFixture', CFBundlePackageType='APPL',
                    CFBundleVersion=str(version), CFBundleShortVersionString=f'0.{version}',
                    LSUIElement=True, LSMinimumSystemVersion='12.0', TestLog=str(log), TestCancel=cancel,
                    SUFeedURL=prefix+'appcast.xml', SUPublicEDKey=public_key,
                    SUEnableAutomaticChecks=False, SUVerifyUpdateBeforeExtraction=True,
                    NSAppTransportSecurity={'NSAllowsLocalNetworking': True})
        with (contents / 'Info.plist').open('wb') as f:
            plistlib.dump(info, f)
        run('codesign', '--force', '--sign', '-', app)
        return app

    old = app_at(base / 'installed', 1)
    new = app_at(base / 'new', 2)
    archive = served / 'update.zip'
    run('ditto', '-c', '-k', '--sequesterRsrc', '--keepParent', new, archive)
    run('bash', ROOT / 'scripts/sign-appcast.sh',
        '--download-url-prefix', prefix, '--maximum-deltas', '0', served)

    def wait_for(text, seconds=45):
        end = time.monotonic() + seconds
        while time.monotonic() < end:
            if text in log.read_text():
                return
            time.sleep(0.2)
        raise AssertionError('Timed out: ' + text + '\n' + log.read_text())

    try:
        current = app_at(base / 'current', 3)
        run('open', '-n', current)
        wait_for('no-update')
        print('PASS: current version reports no update', flush=True)
        time.sleep(1)
        log.write_text('')
        cancelled = app_at(base / 'cancelled', 1, cancel=True)
        run('open', '-n', cancelled)
        wait_for('cancelled')
        assert 'downloading' not in log.read_text()
        print('PASS: dismissing the update does not download or install', flush=True)
        time.sleep(1)
        log.write_text('')
        # A tampered archive must be rejected without replacing the current app.
        original = archive.read_bytes()
        archive.write_bytes(original + b'tampered')
        run('open', '-n', old)
        wait_for('error:')
        with (old / 'Contents/Info.plist').open('rb') as f:
            assert plistlib.load(f)['CFBundleVersion'] == '1'
        assert 'installing' not in log.read_text()
        print('PASS: tampered update rejected; installed app preserved', flush=True)
        time.sleep(1)
        archive.write_bytes(original)
        log.write_text('')
        run('open', '-n', old)
        wait_for('relaunched-version-2')
        with (old / 'Contents/Info.plist').open('rb') as f:
            assert plistlib.load(f)['CFBundleVersion'] == '2'
        assert 'installing' in log.read_text()
        run('codesign', '--verify', '--deep', '--strict', old)
        print('PASS: signed update downloaded, installed in place, and relaunched as version 2', flush=True)
    finally:
        server.shutdown()
        subprocess.run(['pkill', '-f', str(old / 'Contents/MacOS/UpdaterFixture')], check=False)
