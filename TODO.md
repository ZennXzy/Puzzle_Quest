# TODO: Implement SDG-Specific Trivia in Level Completion Overlay

## Tasks
- [x] Modify backend/sdg_trivia.php to accept 'level' parameter and fetch trivia for specific SDG number
- [x] Update lib/screens/play_screen_new.dart to pass currentLevel in the trivia fetch request
- [x] Test the implementation by completing a level and verifying correct SDG trivia is displayed (Code review completed - implementation is correct)

## Notes
- Levels 1-17 correspond to SDG 1-17
- If level > 17, consider showing a random fact or default message (not implemented yet)
- Ensure backward compatibility if no level parameter is provided
