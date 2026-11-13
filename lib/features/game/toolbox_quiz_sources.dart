import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import '../../core/network/supabase_service.dart';
import 'game_save.dart';
import 'lucky_toolbox.dart';

// The lucky toolbox's quiz from Supabase (supabase/toolbox_quiz.sql):
// toolbox_quiz_question() gives one random hourly-bank question without its
// answer, toolbox_quiz_check(id, choice) grades it and awards nothing (no
// hourly points). Fallback order (standardToolboxQuiz): Supabase → quizzes of
// passed lessons cached on this phone (+ won life skills) → no quiz task.

/// Calls a Supabase RPC (injectable for tests).
typedef ToolboxRpc = Future<Object?> Function(String fn, Map<String, dynamic> params);

Future<Object?> _supabaseRpc(String fn, Map<String, dynamic> params) async {
  if (!SupabaseService.hasClient) throw StateError('no supabase');
  return SupabaseService.client.rpc(fn, params: params);
}

class SupabaseToolboxQuizSource implements ToolboxQuizSource {
  SupabaseToolboxQuizSource({ToolboxRpc? rpc, this.timeout = const Duration(seconds: 3)}) : _rpc = rpc ?? _supabaseRpc;

  final ToolboxRpc _rpc;

  /// Short: the chest is waiting (offline phones fall back at once).
  final Duration timeout;

  static Map<String, dynamic>? _row(Object? raw) {
    var v = raw;
    if (v is String) {
      try {
        v = jsonDecode(v);
      } catch (_) {
        return null;
      }
    }
    if (v is List) v = v.isEmpty ? null : v.first;
    return v is Map ? Map<String, dynamic>.from(v) : null;
  }

  static List<String> _options(Object? raw) {
    var v = raw;
    if (v is String) {
      try {
        v = jsonDecode(v);
      } catch (_) {
        return const [];
      }
    }
    if (v is! List) return const [];
    return [for (final o in v) (o?.toString() ?? '').trim()];
  }

  @override
  Future<ToolboxQuizQuestion?> next(GameSave save, math.Random rng) async {
    try {
      final row = _row(await _rpc('toolbox_quiz_question', const {}).timeout(timeout));
      if (row == null) return null;
      final id = row['id']?.toString() ?? '';
      final text = (row['text'] ?? row['question_text'])?.toString().trim() ?? '';
      final options = _options(row['options']);
      if (id.isEmpty || text.isEmpty || options.length < 2 || options.any((o) => o.isEmpty)) return null;
      // Picture options are left out (they may need the network).
      if (options.any((o) => o.startsWith('http') || o.startsWith('/'))) return null;
      return ToolboxQuizQuestion(text: text, options: options, serverId: id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ToolboxQuizVerdict?> check(ToolboxQuizQuestion q, int? choice) async {
    final id = q.serverId;
    if (id == null) return localQuizVerdict(q, choice);
    final picked = choice != null && choice >= 0 && choice < q.options.length ? q.options[choice] : '';
    try {
      final row = _row(await _rpc('toolbox_quiz_check', {'p_question_id': id, 'p_choice': picked}).timeout(timeout));
      final right = row?['correct_choice']?.toString().trim();
      if (row == null || right == null || right.isEmpty) return null;
      final at = q.options.indexWhere((o) => o.trim() == right);
      final correct = row['correct'] == true || (picked.isNotEmpty && picked.trim() == right);
      return ToolboxQuizVerdict(correct: correct, correctIndex: at);
    } catch (_) {
      return null;
    }
  }
}

/// The toolbox's quiz: Supabase first, then passed lessons cached on this
/// phone; won life skills are asked first one time in three (and last).
ToolboxQuizSource standardToolboxQuiz({ToolboxQuizSource? server}) => ToolboxQuizChain(
      [server ?? SupabaseToolboxQuizSource(), const CachedLessonQuizSource()],
      sometimesFirst: const LifeSkillQuizSource(),
    );
