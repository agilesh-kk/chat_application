class AchievementImageMapper {
  static String map(String achievementId) {
    switch (achievementId) {
      case "ach_1":
        return "1.png";
      case "ach_2":
        return "2.png";
      case "ach_3":
        return "3.png";
      case "ach_4":
        return "4.png";
      case "ach_5":
        return "5.png";
      case "ach_6":
        return "6.png";
      case "ach_7":
        return "7.png";
      default:
        return "1.png";
    }
  }
}