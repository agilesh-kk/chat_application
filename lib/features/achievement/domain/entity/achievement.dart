class Achievement{
  final double percentage;
  final String level;
  final List<String> unlocked;
  final List<String> collected;
  final List<String> seen;

  Achievement({
    required this.percentage,
    required this.level,
    required this.unlocked,
    required this.collected,
    required this.seen,
  });
}