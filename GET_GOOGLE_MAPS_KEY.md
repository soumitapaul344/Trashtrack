📍 HOW TO GET GOOGLE MAPS API KEY - STEP BY STEP

⚠️ WITHOUT THIS KEY, MAPS WILL NOT SHOW AT ALL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 1: Get SHA-1 Fingerprint
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Run this command in terminal (from project root):
```
cd android
./gradlew signingReport
```

Output will look like:
```
Variant: debugAndroidTest
Config: debug
Store: C:\Users\...\debug.keystore
Alias: androiddebugkey
MD5: ...
SHA1: AA:BB:CC:DD:EE:FF:... (THIS IS WHAT YOU NEED)
SHA-256: ...
```

Copy the SHA1 value (like: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 2: Create Google Cloud Project
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Go to: https://console.cloud.google.com
2. Click "Select a project" → "New Project"
3. Enter: "TrashTrack" (or any name)
4. Click "Create"
5. Wait for project to load

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 3: Enable Maps APIs
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. In Google Cloud Console, go to: "APIs & Services"
2. Click "Enable APIs and Services" (search bar at top)
3. Search for: "Maps SDK for Android"
4. Click it → Click "Enable"
5. Go back, search for: "Maps SDK for iOS"
6. Click it → Click "Enable"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 4: Create API Key
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Go to: "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "API Key"
3. A popup shows your API Key (like: AIzaSyDxxx...)
4. COPY this key

5. Now restrict it:
   - Click on the key you just created
   - Under "Application restrictions" select: "Android"
   - Click "Add package name and fingerprint"
   - Package name: "com.example.trashtrack"
   - SHA-1 fingerprint: Paste the value from Step 1
   - Click "Done"
   - Click "Save"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 5: Add Key to Android App
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

File: android/app/src/main/AndroidManifest.xml

Find (around line 29):
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY" />
```

Replace with:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyDxxx...YOUR_ACTUAL_KEY_HERE" />
```

Example:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyEOOOOOLKx7ROLxxxxxwxxxxkkTU1qLU" />
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 6: Run App
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

In terminal:
```
flutter clean
flutter run
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TEST THE FEATURE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Open app as CITIZEN
2. Create a pickup request
3. Open app as RIDER
4. Accept the pickup request
5. Go back to CITIZEN home
6. See "Live Rider Tracking" card
7. Click map icon (📍) → Should see map with green marker

If still not working:
- Check Flutter logs: flutter logs | grep -i map
- Check Firestore: Do riders/{riderId} have location data?
- Check device location is enabled (Settings → Location)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

COMMON ISSUES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Q: Map shows blank white screen
A: API key is wrong or not enabled for Android

Q: Map shows red "Google Maps Platform rejected" error
A: API key doesn't match SHA-1 fingerprint

Q: Location marker not updating
A: Firestore doesn't have location data OR location permission denied on device

Q: "Could not find Maps" error
A: Google Play Services not installed on emulator

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
