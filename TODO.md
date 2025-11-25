# TODO: Recreate Login and Registration Process with Local Storage

## Current Status
- Registration: Already implemented with local storage using SharedPreferences
- Login: Currently uses backend API, needs to be changed to local authentication

## Tasks
- [ ] Modify login_screen.dart to authenticate against locally stored users
- [ ] Remove backend dependencies from login screen
- [ ] Implement password verification using same hashing as registration
- [ ] Test login functionality with registered accounts
- [ ] Verify session management works correctly

## Implementation Details
- Users stored in SharedPreferences 'local_users' as JSON array
- Each user: {name, email, password_hash, salt, created_at}
- Password hashing: SHA256(salt + password)
- Session: Store 'current_user' in SharedPreferences
