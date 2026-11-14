import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../auth/auth_provider.dart';
import '../duty_slip/duty_slip_engine.dart';
import '../game/content_catalog.dart';
import '../game/game_save.dart';
import '../game/ladder_builder.dart';
import '../shell/shell_providers.dart';

// Cloud backup of the player's progress (docs/LEAGUE.md "Cloud save").
// The GameSave JSON (progress, stars, ◆, toolbox and life skills) plus the
// duty-slip progress key, gzip + base64, version 1, at most 16 KB, stored in
// the player's one `slm_app.league_all` row by `slm_app.save_progress`. The
// server keeps the more advanced save (higher progress rank). Signed-in
// members only, never guests. Deleted with the account.

const cloudSaveVersion = 1;

/// The server refuses anything bigger (`save_progress`).
const cloudSaveMaxBytes = 16 * 1024;

/// After a level result, at most one save per this long.
const cloudSaveEvery = Duration(minutes: 3);

const _gameKey = 'game_save_v1';

/// "How far": ladder position (the furthest passed rung, 1-based) × 10000
/// plus the total stars. Two saves are compared by this number.
int cloudProgressRank(GameSave save, List<String> ladderIds) {
  var position = 0;
  for (var i = 0; i < ladderIds.length; i++) {
    final p = save.rungProgress[ladderIds[i]];
    if (p == 'cleared' || p == 'prove') position = i + 1;
  }
  var stars = 0;
  for (final s in save.starsByRung.values) {
    stars += s.clamp(0, 3);
  }
  return position * 10000 + (stars > 9999 ? 9999 : stars);
}

/// What a cloud save holds.
@immutable
class CloudSaveData {
  const CloudSaveData({required this.game, this.dutySlip});

  /// `GameSave.toJson()`.
  final Map<String, dynamic> game;

  /// The raw `ds_progress_v2` string, when the phone had one.
  final String? dutySlip;
}

String _encode(Map<String, dynamic> game, String? dutySlip) => base64Encode(
      gzip.encode(utf8.encode(jsonEncode({'v': cloudSaveVersion, 'game': game, 'ds': ?dutySlip}))),
    );

/// gzip + base64 of the save. When it is over [cloudSaveMaxBytes] the
/// oldest death log and mistake-book entries are dropped (progress, stars,
/// ◆ and the toolbox always stay). Null when it still does not fit.
String? encodeCloudSave(GameSave save, {String? dutySlip}) {
  final full = _encode(save.toJson(), dutySlip);
  if (full.length <= cloudSaveMaxBytes) return full;
  List<T> tail<T>(List<T> l, int n) => l.length <= n ? l : l.sublist(l.length - n);
  final trimmed = save.copyWith(deathLog: tail(save.deathLog, 20), mistakes: tail(save.mistakes, 30));
  final small = _encode(trimmed.toJson(), dutySlip);
  if (small.length <= cloudSaveMaxBytes) return small;
  final bare = _encode(trimmed.copyWith(deathLog: const [], mistakes: const []).toJson(), dutySlip);
  return bare.length <= cloudSaveMaxBytes ? bare : null;
}

/// Reads a blob made by [encodeCloudSave]; null when it is damaged or from
/// a newer version this app does not know.
CloudSaveData? decodeCloudSave(String blob) {
  try {
    final json = jsonDecode(utf8.decode(gzip.decode(base64Decode(blob))));
    if (json is! Map || json['game'] is! Map) return null;
    final v = (json['v'] as num?)?.toInt() ?? 0;
    if (v < 1 || v > cloudSaveVersion) return null;
    final game = Map<String, dynamic>.from(json['game'] as Map);
    GameSave.fromJson(game); // must parse
    return CloudSaveData(game: game, dutySlip: json['ds'] is String ? json['ds'] as String : null);
  } catch (_) {
    return null;
  }
}

/// The save on the server (`load_progress`).
@immutable
class CloudSaveRemote {
  const CloudSaveRemote({required this.blob, required this.rank, this.version = cloudSaveVersion, this.savedAt});

  final String blob;
  final int rank;
  final int version;
  final DateTime? savedAt;
}

/// What `save_progress` answered.
@immutable
class CloudSaveReply {
  const CloudSaveReply({required this.saved, this.serverRank});

  final bool saved;

  /// The stored rank when the server kept its more advanced save.
  final int? serverRank;
}

/// Network side. Swappable in tests.
abstract class CloudSaveServer {
  const CloudSaveServer();

  /// Throws when the network failed.
  Future<CloudSaveReply> save(String blob, {required int version, required int rank});

  /// Null when nothing is saved. Throws when the network failed.
  Future<CloudSaveRemote?> load();
}

class SupabaseCloudSaveServer extends CloudSaveServer {
  const SupabaseCloudSaveServer();

  @override
  Future<CloudSaveReply> save(String blob, {required int version, required int rank}) async {
    final res = await SupabaseService.client.schema('slm_app').rpc(
      'save_progress',
      params: {'p_blob': blob, 'p_version': version, 'p_progress_rank': rank},
    );
    if (res is Map && res['success'] == true) return const CloudSaveReply(saved: true);
    return CloudSaveReply(saved: false, serverRank: res is Map ? (res['rank'] as num?)?.toInt() : null);
  }

  @override
  Future<CloudSaveRemote?> load() async {
    final res = await SupabaseService.client.schema('slm_app').rpc('load_progress');
    if (res is! Map || res['success'] != true) throw StateError('load_progress refused');
    final blob = res['blob']?.toString() ?? '';
    if (blob.isEmpty) return null;
    return CloudSaveRemote(
      blob: blob,
      rank: (res['rank'] as num?)?.toInt() ?? 0,
      version: (res['version'] as num?)?.toInt() ?? cloudSaveVersion,
      savedAt: DateTime.tryParse(res['saved_at']?.toString() ?? ''),
    );
  }
}

List<String>? _ladderCache;

Future<List<String>> _catalogLadderIds() async {
  final cached = _ladderCache;
  if (cached != null) return cached;
  final ladder = const LadderBuilder().build(await ContentCatalog.loadAsset());
  return _ladderCache = [for (final r in ladder.rungs) r.id];
}

/// Saves at most every [cloudSaveEvery] after a level result and when the
/// app goes to the background; offers the server's save after sign-in when
/// it is further ahead.
class CloudSaveService {
  CloudSaveService({
    this.server = const SupabaseCloudSaveServer(),
    this.clock = DateTime.now,
    Future<List<String>> Function()? ladderIds,
    this.settle = const Duration(seconds: 5),
  }) : ladderIds = ladderIds ?? _catalogLadderIds;

  final CloudSaveServer server;
  final DateTime Function() clock;
  final Future<List<String>> Function() ladderIds;

  /// Wait after a level result so the game has written its save.
  final Duration settle;

  static CloudSaveService instance = CloudSaveService();
  static AppLifecycleListener? _lifecycle;

  /// The signed-in member's account id; null for guests and signed-out.
  /// Set by [CloudSaveHost] from the auth state.
  String? account;

  DateTime? _lastSave;
  String? _lastBlob;
  Timer? _timer;

  /// The rank the server kept the last time it refused an older save.
  int? lastServerRank;

  /// Hooks level results (after the league's hook) and app background.
  /// Called once from `main.dart`, after `LeagueService.install()`.
  static void install() {
    final before = GameSaveController.onPlayResult;
    GameSaveController.onPlayResult = (rungId, {stars, mark, ms}) {
      before?.call(rungId, stars: stars, mark: mark, ms: ms);
      instance.afterLevelResult();
    };
    _lifecycle ??= AppLifecycleListener(onHide: () => unawaited(instance.saveNow()));
  }

  /// True while a throttled save is waiting (tests).
  bool get saveScheduled => _timer != null;

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  /// A level result was recorded: save after [settle], or when
  /// [cloudSaveEvery] has passed since the last save.
  void afterLevelResult() {
    if (account == null || _timer != null) return;
    final last = _lastSave;
    var wait = settle;
    if (last != null) {
      final left = cloudSaveEvery - clock().difference(last);
      if (left > wait) wait = left;
    }
    _timer = Timer(wait, () {
      _timer = null;
      unawaited(saveNow());
    });
  }

  /// Saves now (app background, or the throttle's turn). Skips guests, an
  /// unchanged save and one over the size cap. Returns true when the server
  /// stored it. Never throws.
  Future<bool> saveNow() async {
    _timer?.cancel();
    _timer = null;
    final uid = account;
    if (uid == null) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_gameKey);
      if (raw == null || raw.isEmpty) return false;
      final save = GameSave.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      final blob = encodeCloudSave(save, dutySlip: prefs.getString(DutySlipEngine.progressKey));
      if (blob == null || blob == _lastBlob) return false;
      final rank = cloudProgressRank(save, await ladderIds());
      _lastSave = clock();
      final reply = await server.save(blob, version: cloudSaveVersion, rank: rank);
      if (account != uid) return false;
      if (reply.saved) {
        _lastBlob = blob;
        lastServerRank = null;
        return true;
      }
      lastServerRank = reply.serverRank;
      return false;
    } catch (_) {
      return false;
    }
  }

  /// After sign-in: the server's save when it is further ahead than this
  /// phone's, else null. Never throws (offline: null).
  Future<CloudSaveRemote?> offerAfterSignIn() async {
    if (account == null) return null;
    try {
      final remote = await server.load();
      if (remote == null) return null;
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_gameKey);
      final local = raw == null || raw.isEmpty
          ? GameSave.empty
          : GameSave.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      final localRank = cloudProgressRank(local, await ladderIds());
      if (remote.rank <= localRank) return null;
      if (decodeCloudSave(remote.blob) == null) return null;
      return remote;
    } catch (_) {
      return null;
    }
  }

  /// Writes [remote] over this phone's save (game save, duty-slip progress
  /// and the ◆ mirror). The caller reloads the providers. False when the
  /// blob cannot be read.
  Future<bool> restore(CloudSaveRemote remote) async {
    final data = decodeCloudSave(remote.blob);
    if (data == null) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_gameKey, jsonEncode(data.game));
      final ds = data.dutySlip;
      if (ds != null) await prefs.setString(DutySlipEngine.progressKey, ds);
      await prefs.setInt('ds_career_score', GameSave.fromJson(data.game).points);
      _lastBlob = remote.blob;
      _lastSave = clock();
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Keeps [CloudSaveService.account] in step with the sign-in and, once per
/// account per app run, asks "আগের অগ্রগতি ফিরিয়ে আনবেন?" when the server's
/// save is further ahead. Yes restores it and reloads the game save.
class CloudSaveHost extends ConsumerStatefulWidget {
  const CloudSaveHost({super.key, required this.child, this.service});

  final Widget child;

  /// Null: [CloudSaveService.instance].
  final CloudSaveService? service;

  @override
  ConsumerState<CloudSaveHost> createState() => _CloudSaveHostState();
}

class _CloudSaveHostState extends ConsumerState<CloudSaveHost> {
  final _checked = <String>{};

  CloudSaveService get _service => widget.service ?? CloudSaveService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onAuth(ref.read(authProvider));
    });
  }

  void _onAuth(AuthState auth) {
    final p = auth.profile;
    final id = auth.isAuthenticated && p != null && !p.isGuest ? p.id : null;
    if (_service.account != id) _service.dispose();
    _service.account = id;
    if (id == null || !_checked.add(id)) return;
    unawaited(_offer(id));
  }

  Future<void> _offer(String id) async {
    final remote = await _service.offerAfterSignIn();
    if (remote == null || !mounted || _service.account != id) return;
    final bn = ref.read(languageProvider);
    final yes = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RestoreQuestion(bn: bn),
    );
    if (yes != true || !mounted || _service.account != id) return;
    if (await _service.restore(remote)) {
      await ref.read(gameSaveProvider.notifier).reloadFromDisk();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, next) => _onAuth(next));
    return widget.child;
  }
}

class _RestoreQuestion extends StatelessWidget {
  const _RestoreQuestion({required this.bn});

  final bool bn;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SlmColors.navy900,
      title: Text(
        tr(bn, 'আগের অগ্রগতি ফিরিয়ে আনবেন?', 'Bring back your earlier progress?'),
        style: bangla(fontSize: 18, fontWeight: FontWeight.w800, color: SlmColors.ivory, height: 1.3),
      ),
      content: Text(
        tr(bn, 'এই অ্যাকাউন্টে আরও এগোনো অগ্রগতি সেভ করা আছে। ফিরিয়ে আনলে এই ফোনের অগ্রগতির জায়গায় সেটা বসবে।',
            'This account has further progress saved. Bringing it back replaces the progress on this phone.'),
        style: bangla(fontSize: 14.5, fontWeight: FontWeight.w500, color: SlmColors.mist, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(tr(bn, 'এখন না', 'Not now'),
              style: bangla(fontSize: 15, fontWeight: FontWeight.w700, color: SlmColors.mist)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(tr(bn, 'হ্যাঁ', 'Yes'),
              style: bangla(fontSize: 15, fontWeight: FontWeight.w800, color: SlmColors.gold300)),
        ),
      ],
    );
  }
}
