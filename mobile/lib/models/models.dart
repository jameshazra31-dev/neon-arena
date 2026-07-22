library models;

class Profile {
  final String id, username, referralCode, language;
  final String? phone, avatarUrl;
  final bool isAdmin, isBanned;
  final double walletBalance;
  Profile.fromJson(Map<String, dynamic> j)
      : id = j['id'], username = j['username'] ?? '', phone = j['phone'],
        avatarUrl = j['avatar_url'], isAdmin = j['is_admin'] ?? false,
        isBanned = j['is_banned'] ?? false, referralCode = j['referral_code'] ?? '',
        walletBalance = (j['wallet_balance'] as num?)?.toDouble() ?? 0, language = j['language'] ?? 'en';
}

class GameProfile {
  final String game, gameUid, ign;
  final String? teamName;
  GameProfile.fromJson(Map<String, dynamic> j)
      : game = j['game'], gameUid = j['game_uid'] ?? '', ign = j['ign'] ?? '', teamName = j['team_name'];
}

class Tournament {
  final String id, name, game, status;
  final String? bannerUrl, mapName, mode, rules, upiId, upiQrUrl;
  final double entryFee, prizePool, perKillPrize;
  final DateTime startTime;
  final int totalSlots;
  final bool isFeatured;
  int? availableSlots;
  Tournament.fromJson(Map<String, dynamic> j)
      : id = j['id'], name = j['name'] ?? '', game = j['game'] ?? '', bannerUrl = j['banner_url'],
        entryFee = (j['entry_fee'] as num?)?.toDouble() ?? 0, prizePool = (j['prize_pool'] as num?)?.toDouble() ?? 0,
        perKillPrize = (j['per_kill_prize'] as num?)?.toDouble() ?? 0, startTime = DateTime.parse(j['start_time']).toLocal(),
        totalSlots = j['total_slots'] ?? 0, mapName = j['map_name'], mode = j['mode'], rules = j['rules'],
        status = j['status'] ?? 'upcoming', isFeatured = j['is_featured'] ?? false, upiId = j['upi_id'], upiQrUrl = j['upi_qr_url'];
}

class Participant {
  final String id, tournamentId, status;
  final String? adminNote;
  final double amountDue;
  final Tournament? tournament;
  Participant.fromJson(Map<String, dynamic> j)
      : id = j['id'], tournamentId = j['tournament_id'], status = j['status'] ?? 'pending',
        adminNote = j['admin_note'], amountDue = (j['amount_due'] as num?)?.toDouble() ?? 0,
        tournament = j['tournaments'] == null ? null : Tournament.fromJson(j['tournaments']);
}

class RoomDetails {
  final String roomId, roomPassword;
  final DateTime? matchTime;
  RoomDetails.fromJson(Map<String, dynamic> j)
      : roomId = j['room_id'] ?? '', roomPassword = j['room_password'] ?? '',
        matchTime = j['match_time'] == null ? null : DateTime.parse(j['match_time']).toLocal();
}

class MatchResult {
  final int rank, kills;
  final double prizeAmount;
  final String prizeStatus;
  final String? username, tournamentName;
  MatchResult.fromJson(Map<String, dynamic> j)
      : rank = j['rank'] ?? 0, kills = j['kills'] ?? 0, prizeAmount = (j['prize_amount'] as num?)?.toDouble() ?? 0,
        prizeStatus = j['prize_status'] ?? 'pending', username = j['profiles']?['username'], tournamentName = j['tournaments']?['name'];
}

class AppNotification {
  final String id, title, body, kind;
  final bool isRead;
  final DateTime createdAt;
  AppNotification.fromJson(Map<String, dynamic> j)
      : id = j['id'], title = j['title'] ?? '', body = j['body'] ?? '', kind = j['kind'] ?? 'general',
        isRead = j['is_read'] ?? false, createdAt = DateTime.parse(j['created_at']).toLocal();
}

class LeaderboardEntry {
  final String username;
  final String? avatarUrl;
  final int tournamentsWon, totalKills;
  final double totalWinnings;
  LeaderboardEntry.fromJson(Map<String, dynamic> j)
      : username = j['username'] ?? '', avatarUrl = j['avatar_url'],
        tournamentsWon = j['tournaments_won'] ?? 0, totalKills = j['total_kills'] ?? 0,
        totalWinnings = (j['total_winnings'] as num?)?.toDouble() ?? 0;
}
