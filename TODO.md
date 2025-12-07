# TODO: Implement Progression Save to Firebase using Local Backend as Reference

## Completed Tasks
- [x] Modified `backend/load_progress.php` to load progress from Firebase Firestore via REST API with local fallback
- [x] Updated `lib/services/progress_service.dart` to use backend endpoints instead of direct Firebase calls
- [x] Verified `backend/save_progress.php` already saves to Firebase Firestore via REST API
- [x] Confirmed http package is available in pubspec.yaml

## Followup Steps
- [ ] Test saving/loading progress with achievements
- [ ] Verify Firebase data consistency
- [ ] Update any other screens that load progress if needed
- [ ] Ensure ID token is passed from Flutter app to backend endpoints
- [ ] Test fallback to local database when Firebase is unavailable
