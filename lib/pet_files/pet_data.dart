class StreakPet {
  final String id;
  String name;
  int currentLevel;
  int growthPoints;
  int currentStreak;
  String currentStage;
  int coins;
  String rank;
  String title;
  double expMultiplier;

  StreakPet({
    required this.id,
    required this.name,
    required this.coins,
    this.currentLevel = 1,
    this.growthPoints = 0,
    this.currentStreak = 0,
    this.currentStage = 'egg',
    this.rank = 'Bronze',
    this.title = 'Sleepy Egg',
    this.expMultiplier = 1.0,
  });


  // Converts a Map (read from local storage) back into a StreakPet object
  factory StreakPet.fromJson(Map<String, dynamic> json) {
    return StreakPet(
      id: json['id'] as String,
      name: json['name'] as String,
      currentLevel: json['currentLevel'] as int,
      growthPoints: json['growthPoints'] as int,
      currentStreak: json['currentStreak'] as int,
      currentStage: json['currentStage'] as String,
      coins: json['coins'] ?? 0,
      rank: json['rank'] ?? 'Bronze',
      title: json['title'] ?? 'Sleepy Egg',
      expMultiplier: (json['expMultiplier'] ?? 1.0).toDouble(),
    );
  }

  // Converts the StreakPet object into a Map so it can be saved as a JSON string
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'currentLevel': currentLevel,
      'growthPoints': growthPoints,
      'currentStreak': currentStreak,
      'currentStage': currentStage,
      'coins': coins,
      'rank': rank,
      'title': title,
      'expMultiplier': expMultiplier,
    };
  }

  // Inside your StreakPet class in pet_data.dart:

  // We keep tracking total lifetime credits synced to total lifetime coins earned
  void rewardCoinsFromCredits(int totalAccumulatedCredits) {
    // Rule: 1 credit = 1 coin
    int targetTotalCoins = totalAccumulatedCredits;
    
    // If the student registered new credits, award them the difference!
    if (targetTotalCoins > this.coins) {
      this.coins = targetTotalCoins; 
    }
  }

  void completeTaskReward({
    int expReward = 20, 
    int coinReward = 5,
  }) {
    // Apply multiplier bonus
    int boostedEXP = (expReward * expMultiplier).toInt();

    // Add rewards
    coins += coinReward;
    growthPoints += boostedEXP;

    // Level up loop
    while (growthPoints >= 100) {
      growthPoints -= 100;
      currentLevel += 1;
    }

    // Evolution stages
    if (currentLevel >= 10) {
      currentStage = 'adult';
    } else if (currentLevel >= 5) {
      currentStage = 'juvenile';
    } else if (currentLevel >= 2) {
      currentStage = 'baby';
    } else {
      currentStage = 'egg';
    }

    // Rank progression
    if (currentLevel >= 15) {
      rank = 'Diamond';
      title = 'Legendary Scholar';
    } else if (currentLevel >= 10) {
      rank = 'Gold';
      title = 'Productivity Wizard';
    } else if (currentLevel >= 5) {
      rank = 'Silver';
      title = 'Focus Apprentice';
    } else {
      rank = 'Bronze';
      title = 'Sleepy Egg';
    }

    // Chain multiplier system
    if (currentStreak >= 30) {
      expMultiplier = 2.5;
    } else if (currentStreak >= 14) {
      expMultiplier = 2.0;
    } else if (currentStreak >= 7) {
      expMultiplier = 1.5;
    } else if (currentStreak >= 3) {
      expMultiplier = 1.2;
    } else {
      expMultiplier = 1.0;
    }
  }
}