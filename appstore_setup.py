"""ASC API: Ghost Sonar app creation + metadata + pricing + age rating + review submission"""
import json
import time
import base64
import jwt
import requests

KEY_ID = "WDXGY9WX55"
ISSUER_ID = "2be0734f-943a-4d61-9dc9-5d9045c46fec"
KEY_PATH = r"C:\Users\Windows\Downloads\AuthKey_WDXGY9WX55.p8"
BUNDLE_ID = "com.snarfnet.ghostsonar"
APP_NAME = "Ghost Sonar"

BASE = "https://api.appstoreconnect.apple.com/v1"

def get_token():
    with open(KEY_PATH, "r") as f:
        key = f.read()
    now = int(time.time())
    payload = {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, key, algorithm="ES256", headers={"kid": KEY_ID})

def h():
    return {"Authorization": f"Bearer {get_token()}", "Content-Type": "application/json"}

def api(method, path, **kwargs):
    url = f"{BASE}{path}" if path.startswith("/") else path
    r = requests.request(method, url, headers=h(), **kwargs)
    return r

# ── 1. Bundle ID + App ──
def get_or_create_bundle_id():
    r = api("GET", f"/bundleIds?filter[identifier]={BUNDLE_ID}")
    if r.status_code == 200 and r.json()["data"]:
        bid = r.json()["data"][0]["id"]
        print(f"Bundle ID exists: {bid}")
        return bid
    r = api("POST", "/bundleIds", json={"data": {
        "type": "bundleIds",
        "attributes": {"identifier": BUNDLE_ID, "name": "GhostSonar", "platform": "IOS"}
    }})
    print(f"Register bundle ID: {r.status_code}")
    if r.status_code == 201:
        return r.json()["data"]["id"]
    print(r.text[:500])
    return None

def create_app():
    bid = get_or_create_bundle_id()
    if not bid:
        return None
    r = api("POST", "/apps", json={"data": {
        "type": "apps",
        "attributes": {"bundleId": BUNDLE_ID, "name": APP_NAME, "primaryLocale": "en-US", "sku": "ghostsonar2026"},
        "relationships": {"bundleId": {"data": {"type": "bundleIds", "id": bid}}}
    }})
    print(f"Create app: {r.status_code}")
    if r.status_code == 201:
        app_id = r.json()["data"]["id"]
        print(f"App ID: {app_id}")
        return app_id
    print(r.text[:500])
    return find_existing_app()

def find_existing_app():
    r = api("GET", f"/apps?filter[bundleId]={BUNDLE_ID}")
    if r.status_code == 200 and r.json()["data"]:
        app_id = r.json()["data"][0]["id"]
        print(f"Existing App ID: {app_id}")
        return app_id
    return None

# ── 2. Category + Content Rights ──
def setup_metadata(app_id):
    r = api("GET", f"/apps/{app_id}/appInfos")
    app_info_id = r.json()["data"][0]["id"]
    print(f"App Info ID: {app_info_id}")

    # Category: Entertainment
    r = api("PATCH", f"/appInfos/{app_info_id}", json={"data": {
        "type": "appInfos", "id": app_info_id,
        "relationships": {
            "primaryCategory": {"data": {"type": "appCategories", "id": "ENTERTAINMENT"}},
            "secondaryCategory": {"data": {"type": "appCategories", "id": "UTILITIES"}}
        }
    }})
    print(f"Set category: {r.status_code}")

    # Content rights
    r = api("PATCH", f"/apps/{app_id}", json={"data": {
        "type": "apps", "id": app_id,
        "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"}
    }})
    print(f"Content rights: {r.status_code}")

    # Privacy policy URL on appInfoLocalizations
    r = api("GET", f"/appInfos/{app_info_id}/appInfoLocalizations")
    if r.status_code == 200:
        for loc in r.json()["data"]:
            loc_id = loc["id"]
            locale = loc["attributes"]["locale"]
            api("PATCH", f"/appInfoLocalizations/{loc_id}", json={"data": {
                "type": "appInfoLocalizations", "id": loc_id,
                "attributes": {"privacyPolicyUrl": "https://snarfnet.github.io/"}
            }})
            print(f"Privacy URL ({locale}): set")

    # Add ja localization for appInfo
    r = api("POST", "/appInfoLocalizations", json={"data": {
        "type": "appInfoLocalizations",
        "attributes": {"locale": "ja", "name": "Ghost Sonar"},
        "relationships": {"appInfo": {"data": {"type": "appInfos", "id": app_info_id}}}
    }})
    print(f"Add ja appInfo: {r.status_code}")

    # Age rating
    setup_age_rating(app_info_id)
    return app_info_id

# ── 3. Age Rating ──
def setup_age_rating(app_info_id):
    r = api("GET", f"/appInfos/{app_info_id}/ageRatingDeclaration")
    if r.status_code != 200:
        print(f"Age rating GET failed: {r.status_code}")
        return
    ard_id = r.json()["data"]["id"]

    r = api("PATCH", f"/ageRatingDeclarations/{ard_id}", json={"data": {
        "type": "ageRatingDeclarations", "id": ard_id,
        "attributes": {
            # Horror theme = INFREQUENT_OR_MILD for this entertainment app
            "horrorOrFearThemes": "INFREQUENT_OR_MILD",
            "violenceCartoonOrFantasy": "NONE",
            "violenceRealistic": "NONE",
            "violenceRealisticProlongedGraphicOrSadistic": "NONE",
            "sexualContentGraphicAndNudity": "NONE",
            "sexualContentOrNudity": "NONE",
            "profanityOrCrudeHumor": "NONE",
            "matureOrSuggestiveThemes": "NONE",
            "alcoholTobaccoOrDrugUseOrReferences": "NONE",
            "gamblingSimulated": "NONE",
            "medicalOrTreatmentInformation": "NONE",
            "contests": "NONE",
            "gunsOrOtherWeapons": "NONE",
            # Booleans
            "gambling": False,
            "lootBox": False,
            "unrestrictedWebAccess": False,
            "gambling": False,
            "advertising": True,  # AdMob
            "userGeneratedContent": False,
            "messagingAndChat": False,
            "parentalControls": False,
            "healthOrWellnessTopics": False,
            "ageAssurance": False
        }
    }})
    print(f"Age rating: {r.status_code}")

# ── 4. Version + Localizations ──
def setup_version(app_id):
    r = api("GET", f"/apps/{app_id}/appStoreVersions?filter[platform]=IOS")
    if r.status_code == 200 and r.json()["data"]:
        version_id = r.json()["data"][0]["id"]
        print(f"Existing version: {version_id}")
    else:
        r = api("POST", "/appStoreVersions", json={"data": {
            "type": "appStoreVersions",
            "attributes": {"platform": "IOS", "versionString": "1.0", "copyright": "2026 tokyonasu", "releaseType": "MANUAL"},
            "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}
        }})
        print(f"Create version: {r.status_code}")
        if r.status_code != 201:
            print(r.text[:500])
            return None
        version_id = r.json()["data"]["id"]

    # Copyright
    api("PATCH", f"/appStoreVersions/{version_id}", json={"data": {
        "type": "appStoreVersions", "id": version_id,
        "attributes": {"copyright": "2026 tokyonasu"}
    }})

    # Version localizations
    r = api("GET", f"/appStoreVersions/{version_id}/appStoreVersionLocalizations")
    if r.status_code == 200:
        for loc in r.json()["data"]:
            locale = loc["attributes"]["locale"]
            if locale == "en-US":
                update_en_version(loc["id"])

    # Add ja version localization
    r = api("POST", "/appStoreVersionLocalizations", json={"data": {
        "type": "appStoreVersionLocalizations",
        "attributes": {
            "locale": "ja",
            "description": "iPhoneのセンサーを駆使した超常現象探知アプリ。\n\n磁気センサー、気圧計、マイク、加速度計のリアルデータを使って周囲の異常をスキャンします。\n\n主な機能：\n- 潜水艦ソナー風レーダースキャン画面\n- EMF（電磁場）異常検出\n- EVP（電子音声現象）キャプチャ\n- 気圧の急変検出\n- 振動異常検出\n- 脅威レベル4段階表示\n- 恐怖演出（画面揺れ、赤フラッシュ、グリッチ、ホラーテキスト）\n- ソナーping音と検出アラート\n- 探知ログ記録\n\nエンターテインメント目的のアプリです。実際の超常現象を検出するものではありません。",
            "keywords": "ゴースト,幽霊,心霊,お化け,探知,レーダー,ソナー,EMF,ホラー,怖い,超常現象,肝試し,心霊スポット,センサー",
            "supportUrl": "https://snarfnet.github.io/",
            "marketingUrl": "https://snarfnet.github.io/"
        },
        "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}}
    }})
    print(f"Add ja version: {r.status_code}")

    # Review detail
    r = api("POST", "/appStoreReviewDetails", json={"data": {
        "type": "appStoreReviewDetails",
        "attributes": {
            "contactFirstName": "Tokyo",
            "contactLastName": "Nasu",
            "contactEmail": "snarfnet@gmail.com",
            "contactPhone": "+14155550000",
            "demoAccountRequired": False,
            "demoAccountName": "",
            "demoAccountPassword": "",
            "notes": "Ghost Sonar is an entertainment app that uses real iPhone sensor data (magnetometer, barometer, microphone, accelerometer) to create a ghost detection experience with submarine sonar-style UI. It does not claim to detect actual paranormal activity. The horror effects (screen shake, red flash, glitch) are purely for entertainment."
        },
        "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}}
    }})
    print(f"Review detail: {r.status_code}")

    return version_id

def update_en_version(loc_id):
    r = api("PATCH", f"/appStoreVersionLocalizations/{loc_id}", json={"data": {
        "type": "appStoreVersionLocalizations", "id": loc_id,
        "attributes": {
            "description": "Turn your iPhone into a paranormal detection device with real sensor data.\n\nGhost Sonar uses your iPhone's magnetometer, barometer, microphone, and accelerometer to scan for environmental anomalies — displayed on a submarine sonar-style radar.\n\nFeatures:\n- Submarine sonar radar sweep with real-time detection blips\n- EMF (Electromagnetic Field) anomaly detection\n- EVP (Electronic Voice Phenomena) audio capture\n- Barometric pressure drop detection\n- Vibration anomaly sensing\n- 4-level threat indicator (LOW/MEDIUM/HIGH/CRITICAL)\n- Horror effects: screen shake, red flash, glitch, static noise, horror text\n- Sonar ping and detection alert sounds\n- Detection log with timestamps\n\nFor entertainment purposes only. Does not detect actual paranormal activity.",
            "keywords": "ghost,radar,sonar,detector,emf,paranormal,haunted,horror,scary,spirit,sensor,hunter,spooky,investigation",
            "supportUrl": "https://snarfnet.github.io/",
            "marketingUrl": "https://snarfnet.github.io/"
        }
    }})
    print(f"Update en-US version: {r.status_code}")

# ── 5. Pricing (Free) ──
def set_free_price(app_id):
    pp_data = {"s": app_id, "t": "USA", "p": "10000"}
    pp_id = base64.b64encode(json.dumps(pp_data, separators=(',', ':')).encode()).decode().rstrip('=')

    r = api("POST", "/appPriceSchedules", json={
        "data": {
            "type": "appPriceSchedules",
            "relationships": {
                "app": {"data": {"type": "apps", "id": app_id}},
                "baseTerritory": {"data": {"type": "territories", "id": "USA"}},
                "manualPrices": {"data": [{"type": "appPrices", "id": "${usa-free}"}]}
            }
        },
        "included": [{
            "type": "appPrices",
            "id": "${usa-free}",
            "attributes": {"startDate": None, "endDate": None},
            "relationships": {
                "territory": {"data": {"type": "territories", "id": "USA"}},
                "appPricePoint": {"data": {"type": "appPricePoints", "id": pp_id}}
            }
        }]
    })
    print(f"Set free price: {r.status_code}")
    if r.status_code not in (201, 200, 409):
        print(r.text[:500])

if __name__ == "__main__":
    print("=== Ghost Sonar ASC Setup ===\n")
    app_id = find_existing_app() or create_app()
    if not app_id:
        print("FAILED: Could not create/find app")
        exit(1)

    setup_metadata(app_id)
    version_id = setup_version(app_id)
    set_free_price(app_id)

    print(f"\n=== Done! ===")
    print(f"App ID: {app_id}")
    if version_id:
        print(f"Version ID: {version_id}")
    print(f"Bundle ID: {BUNDLE_ID}")
