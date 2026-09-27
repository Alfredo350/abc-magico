"""Ajusta la carpeta android/ que genera `flutter create`:
- nombre visible de la app: ABC Mágico
- solo vertical
- permiso de internet (para descargar la tipografía la primera vez)
- permiso para usar el motor de voz (Android 11+)
"""
import pathlib
import re

m = pathlib.Path("android/app/src/main/AndroidManifest.xml")
s = m.read_text(encoding="utf-8")

s = re.sub(r'android:label="[^"]*"', 'android:label="ABC Mágico"', s, count=1)

if "android.permission.INTERNET" not in s:
    s = s.replace("<application", '<uses-permission android:name="android.permission.INTERNET"/>\n    <application', 1)

if "screenOrientation" not in s:
    s = s.replace('android:name=".MainActivity"', 'android:name=".MainActivity"\n            android:screenOrientation="portrait"', 1)

tts = '<intent>\n            <action android:name="android.intent.action.TTS_SERVICE"/>\n        </intent>'
if "TTS_SERVICE" not in s:
    if "<queries>" in s:
        s = s.replace("<queries>", "<queries>\n        " + tts, 1)
    else:
        s = s.replace("</manifest>", "    <queries>\n        " + tts + "\n    </queries>\n</manifest>", 1)

m.write_text(s, encoding="utf-8")
print("AndroidManifest.xml listo")
