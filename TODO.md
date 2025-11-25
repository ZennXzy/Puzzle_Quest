# TODO: Screens Folder Analysis and Fixes

## Completed Fixes
- [x] Analyzed all screens in lib/screens/ folder
- [x] Removed backend sync from play_screen_new.dart, now uses only local SharedPreferences
- [x] Verified login_screen.dart and registration_screen.dart already use local storage consistently
- [x] Updated main.dart import to use play_screen_new.dart (already correct)
- [x] Fixed authentication flow: both login and registration use local SharedPreferences

## Current Status
- All screens now consistently use local storage for user data and progress
- No backend dependencies in screens folder
- Authentication works offline with hashed passwords

## Implementation Details
- Users stored in SharedPreferences 'local_users' as JSON array
- Each user: {name, email, password_hash, salt, created_at}
- Password hashing: SHA256(salt + password)
- Session: Store 'current_user' in SharedPreferences
- Progress: Store 'user_progress_{username}' in SharedPreferences
