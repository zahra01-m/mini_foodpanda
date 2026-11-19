# Images update

Unzip over the project (paths already match), then `flutter pub get` is NOT needed.

- assets/images/        22 JPGs: 4 restaurant banners + 18 menu photos (flat folder, covered by `assets/images/` in pubspec)
- lib/services/mock_data_service.dart   Brew & Bean now points at its banner + 6 item photos

Existing filenames (Mid City, Fifth Avenue, Sweet Creme) were overwritten in place,
so those need no code change. To see Brew & Bean's pictures in an already-seeded
Firebase project, tap Admin > "Load sample data" again (fixed ids, so it overwrites
instead of duplicating).
