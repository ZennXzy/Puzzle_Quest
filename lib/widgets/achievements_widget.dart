import 'package:flutter/material.dart';
import '../models/user_progress.dart';
import '../models/hard_user_progress.dart';

class AchievementsWidget extends StatefulWidget {
  final UserProgress? userProgress;
  final HardUserProgress? hardUserProgress;

  const AchievementsWidget({
    super.key,
    required this.userProgress,
    required this.hardUserProgress,
  });

  @override
  State<AchievementsWidget> createState() => _AchievementsWidgetState();
}

class _AchievementsWidgetState extends State<AchievementsWidget> {
  String _selectedAchievement = 'Classic'; // Classic or Hard

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Achievements',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white.withOpacity(0.8),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => _selectedAchievement = 'Classic'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedAchievement == 'Classic'
                      ? Colors.deepPurple
                      : Colors.grey,
                ),
                child: const Text('Classic'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => _selectedAchievement = 'Hard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedAchievement == 'Hard'
                      ? Colors.deepPurple
                      : Colors.grey,
                ),
                child: const Text('Hard'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedAchievement == 'Classic')
          _buildClassicAchievements()
        else
          _buildHardAchievements(),
      ],
    );
  }

  Widget _buildClassicAchievements() {
    final bestTimes = widget.userProgress?.bestTimes ?? {};
    final calculatedAchievements =
        widget.userProgress?.getCalculatedAchievements() ?? {};
    final fastestSolve = widget.userProgress?.getFastestSolve();
    final averageTime = widget.userProgress?.getAverageBestTime() ?? 0.0;
    final completedCount = widget.userProgress?.completedLevels.length ?? 0;

    final allAchievements = <Widget>[];

    allAchievements.addAll(bestTimes.entries.map((entry) {
      return _buildPerLevelAchievement(entry.key, entry.value);
    }));

    if (fastestSolve != null) {
      allAchievements.add(_buildGlobalAchievement(
        'Fastest Solve',
        'Level ${fastestSolve.key}: ${_formatTime(fastestSolve.value)}',
        Icons.flash_on,
      ));
    }

    if (completedCount > 0) {
      allAchievements.add(_buildGlobalAchievement(
        'Levels Completed',
        '$completedCount/17 Levels',
        Icons.check_circle,
      ));
    }

    if (averageTime > 0) {
      allAchievements.add(_buildGlobalAchievement(
        'Average Best Time',
        _formatTime(averageTime.round()),
        Icons.trending_up,
      ));
    }

    if (calculatedAchievements['under_1_min'] == true) {
      final count = bestTimes.values.where((t) => t < 60).length;
      allAchievements.add(_buildGlobalAchievement(
        'Speed Demon',
        '$count levels under 1 minute',
        Icons.speed,
      ));
    }

    if (calculatedAchievements['under_30_sec'] == true) {
      final count = bestTimes.values.where((t) => t < 30).length;
      allAchievements.add(_buildGlobalAchievement(
        'Lightning Fast',
        '$count levels under 30 seconds',
        Icons.bolt,
      ));
    }

    if (calculatedAchievements['under_10_sec'] == true) {
      final count = bestTimes.values.where((t) => t < 10).length;
      allAchievements.add(_buildGlobalAchievement(
        'Instant Solver',
        '$count levels under 10 seconds',
        Icons.whatshot,
      ));
    }

    if (calculatedAchievements['complete_5'] == true) {
      allAchievements.add(_buildGlobalAchievement(
        'Getting Started',
        'Completed 5 levels',
        Icons.star,
      ));
    }

    if (calculatedAchievements['complete_10'] == true) {
      allAchievements.add(_buildGlobalAchievement(
        'Halfway There',
        'Completed 10 levels',
        Icons.star_half,
      ));
    }

    if (calculatedAchievements['complete_all'] == true) {
      allAchievements.add(_buildGlobalAchievement(
        'Puzzle Master',
        'Completed all 17 levels',
        Icons.workspace_premium,
      ));
    }

    if (allAchievements.isEmpty) {
      return _buildNoAchievements();
    }

    return Column(children: allAchievements);
  }

  Widget _buildHardAchievements() {
    final bestTimes = widget.hardUserProgress?.bestTimes ?? {};
    final calculatedAchievements =
        widget.hardUserProgress?.getCalculatedAchievements() ?? {};
    final fastestSolve = widget.hardUserProgress?.getFastestSolve();
    final averageTime = widget.hardUserProgress?.getAverageBestTime() ?? 0.0;
    final completedCount = widget.hardUserProgress?.completedLevels.length ?? 0;

    final allAchievements = <Widget>[];

    allAchievements.addAll(bestTimes.entries.map((entry) {
      return _buildPerLevelAchievement(entry.key, entry.value,
          borderColor: Colors.red);
    }));

    if (fastestSolve != null) {
      allAchievements.add(_buildGlobalAchievement(
        'Fastest Solve',
        'Level ${fastestSolve.key}: ${_formatTime(fastestSolve.value)}',
        Icons.flash_on,
        borderColor: Colors.red,
      ));
    }

    if (completedCount > 0) {
      allAchievements.add(_buildGlobalAchievement(
        'Levels Completed',
        '$completedCount/17 Levels',
        Icons.check_circle,
        borderColor: Colors.red,
      ));
    }

    if (averageTime > 0) {
      allAchievements.add(_buildGlobalAchievement(
        'Average Best Time',
        _formatTime(averageTime.round()),
        Icons.trending_up,
        borderColor: Colors.red,
      ));
    }

    if (calculatedAchievements['under_3_min'] == true) {
      final count = bestTimes.values.where((t) => t < 180).length;
      allAchievements.add(_buildGlobalAchievement(
        'Persistent',
        '$count levels under 3 minutes',
        Icons.speed,
        borderColor: Colors.red,
      ));
    }

    if (calculatedAchievements['under_2_min'] == true) {
      final count = bestTimes.values.where((t) => t < 120).length;
      allAchievements.add(_buildGlobalAchievement(
        'Determined',
        '$count levels under 2 minutes',
        Icons.bolt,
        borderColor: Colors.red,
      ));
    }

    if (calculatedAchievements['under_1_min'] == true) {
      final count = bestTimes.values.where((t) => t < 60).length;
      allAchievements.add(_buildGlobalAchievement(
        'Hardcore',
        '$count levels under 1 minute',
        Icons.whatshot,
        borderColor: Colors.red,
      ));
    }

    if (allAchievements.isEmpty) {
      return _buildNoAchievements(borderColor: Colors.red);
    }

    return Column(children: allAchievements);
  }

  Widget _buildPerLevelAchievement(int level, int time, {Color? borderColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.04)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
            color: borderColor ?? Colors.white.withOpacity(0.6), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(4, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6E4AA6).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Color(0xFF6E4AA6),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level $level',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Best Time: ${_formatTime(time)}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6E4AA6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF6E4AA6).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer,
                  color: Color(0xFF6E4AA6),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(time),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalAchievement(String title, String subtitle, IconData icon,
      {Color? borderColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.04)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
            color: borderColor ?? Colors.white.withOpacity(0.6), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(4, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6E4AA6).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6E4AA6),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAchievements({Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.06),
            Colors.white.withOpacity(0.03)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
            color: borderColor ?? Colors.white.withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(6, 8),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No achievements yet',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
