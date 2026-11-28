#!/usr/bin/env python3
"""
मंदिर परिसर का PA डिवाइस — यह स्क्रिप्ट हर 2 सेकंड में सर्वर से घोषणा लेकर स्पीकर पर बजाती है।

ज़रूरत: Python 3, `requests`, और कोई TTS/प्लेयर:
  - Raspberry Pi / Linux:  sudo apt install espeak-ng mpg123
  - Windows: NSSM से सर्विस बनाएँ, TTS के लिए PowerShell का System.Speech इस्तेमाल होगा

चलाएँ:
  API=https://api.bsmmandir.org SERVICE_KEY=xxxx python3 pa_device.py
"""

import os
import shutil
import subprocess
import sys
import time

import requests

API = os.environ.get("API", "http://localhost:8080").rstrip("/")
SERVICE_KEY = os.environ.get("SERVICE_KEY", "dev-service-key")
POLL_SECONDS = int(os.environ.get("POLL_SECONDS", "2"))

HEADERS = {"x-service-key": SERVICE_KEY}


def speak(text: str) -> bool:
    """टेक्स्ट को आवाज़ में बदलकर बजाएँ"""
    # 1) espeak-ng (Linux/Raspberry Pi) — हिंदी
    if shutil.which("espeak-ng"):
        return subprocess.call(["espeak-ng", "-v", "hi", "-s", "135", text]) == 0
    if shutil.which("espeak"):
        return subprocess.call(["espeak", "-v", "hi", "-s", "135", text]) == 0

    # 2) Windows — PowerShell SAPI
    if sys.platform.startswith("win"):
        ps = (
            "Add-Type -AssemblyName System.Speech; "
            "$s = New-Object System.Speech.Synthesis.SpeechSynthesizer; "
            f"$s.Speak('{text.replace(chr(39), '')}')"
        )
        return subprocess.call(["powershell", "-Command", ps]) == 0

    # 3) macOS
    if shutil.which("say"):
        return subprocess.call(["say", "-v", "Lekha", text]) == 0

    print("⚠️  कोई TTS नहीं मिला — केवल टेक्स्ट दिखा रहे हैं:", text)
    return False


def main() -> None:
    print(f"PA डिवाइस चालू — {API} (हर {POLL_SECONDS}s पोल)")
    while True:
        try:
            r = requests.get(f"{API}/api/announcements/pending", headers=HEADERS, timeout=10)
            if r.status_code == 401:
                print("❌ service key गलत है"); time.sleep(30); continue
            data = r.json().get("announcement")
            if not data:
                time.sleep(POLL_SECONDS); continue

            print("🔊 घोषणा:", data["text"])
            ok = speak(data["text"])
            endpoint = "played" if ok else "retry"
            requests.post(
                f"{API}/api/announcements/{data['id']}/{endpoint}",
                headers=HEADERS, timeout=10,
            )
        except requests.RequestException as e:
            print("नेटवर्क गड़बड़:", e)
            time.sleep(5)
        except KeyboardInterrupt:
            print("रुका"); break
        time.sleep(0.5)


if __name__ == "__main__":
    main()
