#!/usr/bin/env python3
"""Idempotent patch for the generated AndroidManifest.xml.

* adds the INTERNET permission (Flutter only adds it to debug/profile manifests)
* sets the visible app name
* locks the main activity to landscape (Nuvio is landscape-only)
"""
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
xml = path.read_text(encoding="utf-8")

if "android.permission.INTERNET" not in xml:
    xml = xml.replace(
        "<application",
        '<uses-permission android:name="android.permission.INTERNET"/>\n    <application',
        1,
    )

xml = re.sub(r'android:label="[^"]*"', 'android:label="Nuvio Launcher"', xml, count=1)

if "android:screenOrientation" not in xml:
    xml = xml.replace(
        "<activity",
        '<activity\n            android:screenOrientation="sensorLandscape"',
        1,
    )

# nuvio://auth deep link: lets the website bring the launcher to the foreground after login.
if 'android:scheme="nuvio"' not in xml:
    intent = (
        '<intent-filter>\n'
        '                <action android:name="android.intent.action.VIEW"/>\n'
        '                <category android:name="android.intent.category.DEFAULT"/>\n'
        '                <category android:name="android.intent.category.BROWSABLE"/>\n'
        '                <data android:scheme="nuvio" android:host="auth"/>\n'
        '            </intent-filter>\n            '
    )
    xml = xml.replace("</activity>", intent + "</activity>", 1)

path.write_text(xml, encoding="utf-8")
print(f"patched {path}")
