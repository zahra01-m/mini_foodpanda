# Update: 4 restaurants only + photo upload + image polish

After unzipping over the project:
1. flutter pub get            (adds image_picker)
2. firebase deploy --only firestore:rules   (lets the admin delete old sample docs)
3. STOP the app and run it again (assets/new packages need a full restart, not hot reload)
4. Admin > cloud icon "Load sample data"  -> old restaurants/orders are deleted, new ones written

Photo upload: Admin > Vendors > edit restaurant, or open a restaurant > add/edit item > "Upload photo".
Photos are resized (max 900px) and stored inside the Firestore document, so it works on the free
Firebase plan (Cloud Storage needs the Blaze plan since Feb 2026). Limit ~600 KB per photo.
