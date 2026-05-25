import 'package:flutter/material.dart';
import 'enums.dart';

class Team {
  final String id;
  final String name;
  final String shortCode;
  final TeamCategory category;
  final int? foundedYear;
  final String? homeVenue;
  final Color primaryColor;
  final Color secondaryColor;
  final String? flagUrl;
  final String? captainId;

  // Stats
  final int matchesPlayed;
  final int wins;
  final int losses;
  final int ties;
  final int noResults;

  const Team({
    required this.id,
    required this.name,
    required this.shortCode,
    this.category = TeamCategory.senior,
    this.foundedYear,
    this.homeVenue,
    this.primaryColor = const Color(0xFF0F2447),
    this.secondaryColor = const Color(0xFFD4AF37),
    this.flagUrl,
    this.captainId,
    this.matchesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.ties = 0,
    this.noResults = 0,
  });

  double get winPercentage =>
      matchesPlayed == 0 ? 0 : (wins / matchesPlayed) * 100;

  int get points => (wins * 2) + ties + noResults;
}
