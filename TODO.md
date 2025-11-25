# TODO: Add Targeted Goals to Achievements List

## Tasks
- [ ] Update UserProgress model to include achievements tracking (Map<String, bool> for unlocked achievements)
- [ ] Modify AchievementsWidget to calculate and display new achievement goals:
  - Fastest Solve: Level with overall best time
  - Total Levels Completed: Count of completed levels (e.g., "5/17 Levels Completed")
  - Average Best Time: Average of all best times
  - Speed Achievements: Count levels under 1 min, 30 sec, 10 sec
  - Completion Milestones: Milestones for 5, 10, all levels completed
- [ ] Update backend save_progress.php and load_progress.php to handle achievements field
- [ ] Test the updated widget display and functionality
- [ ] Integrate any additional goals if needed
