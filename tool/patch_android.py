#!/usr/bin/env python3
"""Run once after `flutter create --platforms=android .`

Adds what this app needs to the generated Android project:
  * CAMERA + INTERNET permissions
  * cleartext traffic to localhost (the 3D viewer serves models from a tiny local server)
  * <queries> so the app can open Google's AR viewer
  * minSdk 24
Safe to run more than once.
"""
import re
import sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent
manifest = root / "android/app/src/main/AndroidManifest.xml"
if not manifest.exists():
    sys.exit("Run `flutter create --platforms=android .` first (no android/ folder found).")

text = manifest.read_text()

# --- permissions + camera feature -------------------------------------------------------
perms = (
    '    <uses-permission android:name="android.permission.INTERNET"/>\n'
    '    <uses-permission android:name="android.permission.CAMERA"/>\n'
    '    <uses-feature android:name="android.hardware.camera" android:required="false"/>\n'
)
if "android.permission.CAMERA" not in text:
    text = text.replace("<application", perms + "    <application", 1)

# --- queries (let the app resolve the AR viewer / browser intents) ----------------------
queries = (
    '        <package android:name="com.google.android.googlequicksearchbox"/>\n'
    '        <intent><action android:name="android.intent.action.VIEW"/>'
    '<data android:scheme="https"/></intent>\n'
    '        <intent><action android:name="android.intent.action.VIEW"/>'
    '<data android:scheme="intent"/></intent>\n'
)
if 'android:scheme="intent"' not in text:
    if "<queries>" in text:
        text = text.replace("<queries>", "<queries>\n" + queries, 1)
    else:
        text = text.replace("<application", "    <queries>\n" + queries + "    </queries>\n    <application", 1)

# --- cleartext + app name ---------------------------------------------------------------
if "usesCleartextTraffic" not in text:
    text = text.replace("<application", '<application\n        android:usesCleartextTraffic="true"', 1)
text = re.sub(r'android:label="[^"]*"', 'android:label="Sofa AR"', text, count=1)
manifest.write_text(text)

# --- minSdk -----------------------------------------------------------------------------
for name in ("build.gradle.kts", "build.gradle"):
    gradle = root / "android/app" / name
    if gradle.exists():
        g = gradle.read_text()
        g = re.sub(r"minSdk\s*=\s*flutter\.minSdkVersion", "minSdk = 24", g)
        g = re.sub(r"minSdkVersion\s+flutter\.minSdkVersion", "minSdkVersion 24", g)
        gradle.write_text(g)

# --- the default counter-app test no longer matches our app ------------------------------
default_test = root / "test/widget_test.dart"
if default_test.exists():
    default_test.unlink()

print("Android project patched.")
