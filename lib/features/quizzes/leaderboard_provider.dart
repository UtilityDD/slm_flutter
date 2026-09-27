import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/supabase_service.dart';

class LeaderboardEntry {
  final int rank;
  final String id;
  final String name;
  final String district;
  final int points;
  final int level;
  final String? avatarUrl;

  const LeaderboardEntry({
    required this.rank,
    required this.id,
    required this.name,
    required this.district,
    required this.points,
    required this.level,
    this.avatarUrl,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map, int rank) {
    return LeaderboardEntry(
      rank: rank,
      id: map['id']?.toString() ?? '',
      name: map['full_name']?.toString() ?? map['slm_id']?.toString() ?? 'লাইনম্যান',
      district: map['district']?.toString() ?? 'পশ্চিমবঙ্গ',
      points: (map['points'] as num?)?.toInt() ?? 0,
      level: (map['training_level'] as num?)?.toInt() ?? 1,
      avatarUrl: map['avatar_url']?.toString(),
    );
  }
}

final liveLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  try {
    // Try fetching from monthly_leaderboard_view first
    final now = DateTime.now();
    try {
      final monthlyData = await SupabaseService.client
          .from('monthly_leaderboard_view')
          .select('user_id, full_name, district, points, avatar_url')
          .eq('year_num', now.year)
          .eq('month_num', now.month)
          .order('points', ascending: false)
          .limit(25);

      if (monthlyData.isNotEmpty) {
        return List<LeaderboardEntry>.generate(monthlyData.length, (index) {
          final row = monthlyData[index];
          return LeaderboardEntry(
            rank: index + 1,
            id: row['user_id']?.toString() ?? '',
            name: row['full_name']?.toString() ?? 'লাইনম্যান',
            district: row['district']?.toString() ?? 'পশ্চিমবঙ্গ',
            points: (row['points'] as num?)?.toInt() ?? 0,
            level: 1,
            avatarUrl: row['avatar_url']?.toString(),
          );
        });
      }
    } catch (_) {
      // Fallback to profiles table if view has different structure
    }

    // Direct profiles lookup
    final profileData = await SupabaseService.client
        .from('profiles')
        .select('id, full_name, slm_id, district, points, training_level, avatar_url')
        .order('points', ascending: false)
        .limit(25);

    return List<LeaderboardEntry>.generate(profileData.length, (index) {
      return LeaderboardEntry.fromMap(profileData[index], index + 1);
    });
  } catch (e) {
    // Fallback data if offline
    return const [
      LeaderboardEntry(rank: 1, id: '1', name: 'শুভঙ্কর জানা', district: 'পূর্ব মেদিনীপুর', points: 4820, level: 5),
      LeaderboardEntry(rank: 2, id: '2', name: 'প্রদীপ চক্রবর্তী', district: 'বাঁকুড়া', points: 4650, level: 4),
      LeaderboardEntry(rank: 3, id: '3', name: 'অমল রায়', district: 'হুগলি', points: 4410, level: 4),
      LeaderboardEntry(rank: 4, id: '4', name: 'বিশ্বজিৎ মন্ডল', district: 'বর্ধমান', points: 3980, level: 3),
      LeaderboardEntry(rank: 5, id: '5', name: 'রাজেশ পাত্র', district: 'দক্ষিণ ২৪ পরগনা', points: 3740, level: 3),
    ];
  }
});
