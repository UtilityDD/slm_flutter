/// Which owner-approved welcome (W01–W10) the guide Subrata says on a ladder
/// open. The lines themselves live in [MascotSpeechLibrary.welcomeCue].
enum WelcomeSituation {
  /// W01: brand-new player, very first ladder open.
  firstEver,

  /// W02: new player, a later open before level 1 is cleared.
  newBeforeL1,

  /// W08: the last session ended with a deadly mistake (death).
  afterDeath,

  /// W09: a rank-up / module finished since the last open.
  afterRankUp,

  /// W07: first open after 3 or more days away.
  afterBreak,

  /// W10: first open of the day, signed-in player whose name is known.
  dailyNamed,

  /// W03: first open of the day, before 12:00.
  dailyMorning,

  /// W04: first open of the day, 12:00 up to 17:00.
  dailyAfternoon,

  /// W05: first open of the day, from 17:00.
  dailyEvening,

  /// W06: again later the same day.
  sameDay,
}

/// Days away that count as a break (W07).
const welcomeBreakDays = 3;

/// Calendar days between [from] and [to] (local dates; DST-safe).
int welcomeDaysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// Picks the welcome for a ladder open at [now].
///
/// Priority (owner, 2026-11-14): W01 > W02 > W08 > W09 > W07 >
/// first of the day (W10 with a name, else W03/W04/W05 by local time) > W06.
/// A null [lastLadderOpen] (older saves) counts as the first open of the day.
WelcomeSituation chooseWelcome({
  required DateTime now,
  required DateTime? lastLadderOpen,
  required bool l1Cleared,
  required bool isFirstEver,
  required bool diedLastSession,
  required bool rankedUpSinceLastOpen,
  required String? name,
}) {
  if (isFirstEver) return WelcomeSituation.firstEver;
  if (!l1Cleared) return WelcomeSituation.newBeforeL1;
  if (diedLastSession) return WelcomeSituation.afterDeath;
  if (rankedUpSinceLastOpen) return WelcomeSituation.afterRankUp;
  final daysAway = lastLadderOpen == null ? 0 : welcomeDaysBetween(lastLadderOpen, now);
  if (daysAway >= welcomeBreakDays) return WelcomeSituation.afterBreak;
  if (lastLadderOpen == null || daysAway != 0) {
    if (name != null && name.trim().isNotEmpty) return WelcomeSituation.dailyNamed;
    if (now.hour < 12) return WelcomeSituation.dailyMorning;
    if (now.hour < 17) return WelcomeSituation.dailyAfternoon;
    return WelcomeSituation.dailyEvening;
  }
  return WelcomeSituation.sameDay;
}
