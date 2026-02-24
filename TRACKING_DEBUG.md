✅ TRACKING UI DEBUGGING CHECKLIST

=== ISSUE: Tracking map not showing ===

🔴 CRITICAL - Google Maps API Key Missing
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Current: YOUR_GOOGLE_MAPS_API_KEY (placeholder - NOT WORKING)
File: android/app/src/main/AndroidManifest.xml (line 29)

ACTION REQUIRED:
  1. Go to: https://console.cloud.google.com
  2. Create/Select your project
  3. Enable these APIs:
     - Maps SDK for Android
     - Maps SDK for iOS (if iOS)
  4. Create API Key:
     - Go to: Credentials → Create Credentials → API Key
     - Select: Android
     - Accept SHA-1 fingerprint (from error or certificate)
     - Copy the generated key

  5. Replace in AndroidManifest.xml:
     BEFORE: android:value="YOUR_GOOGLE_MAPS_API_KEY"
     AFTER:  android:value="AIzaSyx..." (your actual key)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ CHECK: Location Permissions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
File: android/app/src/main/AndroidManifest.xml

Status: ✓ Permissions configured:
  ✓ ACCESS_FINE_LOCATION
  ✓ ACCESS_COARSE_LOCATION
  ✓ FOREGROUND_SERVICE
  ✓ FOREGROUND_SERVICE_LOCATION

ACTION: On device, grant location permission when app asks:
  - Open App
  - When prompted: "Allow location access" → Tap "Allow"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ CHECK: Firestore Data Structure
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Required Collections in Firestore:

1. riders/{riderId}
   ├── latitude: double (e.g., 23.8103)
   ├── longitude: double (e.g., 90.3563)
   └── lastUpdated: timestamp

2. citizens/{citizenId}
   ├── latitude: double
   ├── longitude: double
   └── lastUpdated: timestamp

VERIFY: Go to Firebase Console → Firestore → Check if data exists

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ FLOW: How Tracking Should Work
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CITIZEN SIDE:
  1. Citizen creates pickup request
  2. Rider accepts request
  3. Citizen Home shows "Live Rider Tracking" card
  4. Click map icon (📍) → Full screen map loads
  5. See rider location with green marker

RIDER SIDE:
  1. Pickup request created
  2. Rider accepts → Shows "Track" button
  3. Click "Track" button (🗺️) → Full screen map loads
  4. See citizen location with blue marker

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 DEBUGGING STEPS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Step 1: Run app with API key configured
  flutter run

Step 2: Check logcat for errors
  flutter logs | grep -i "map\|location\|geolocator"

Step 3: Verify location is being captured
  Check Firestore: riders/{userId} has latitude/longitude

Step 4: Test tracking page
  - Rider accepts pickup
  - See "Track" button appears
  - Click it → Map should load with blue marker

Step 5: If map doesn't load:
  - Check: Does Firestore have location data?
  - Check: Is Google Maps API key correct?
  - Check: Is Android SDK target correct? (minSdkVersion >= 21)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 NEXT STEPS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Get actual Google Maps API Key
2. Update AndroidManifest.xml with key
3. Run: flutter clean && flutter run
4. Test: Create pickup → Accept → Click Track/Map button
5. Send logcat if still not working
