import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../design/slm_design.dart';
import '../game/game_save.dart';
import 'life_skill_audio.dart';
import 'life_skills_data.dart';

// "আমার জীবন দক্ষতা": the life skills won from the lucky toolbox. A simple
// list → detail (card, sections, pro tip, myth buster, narration with a
// progress bar). Nothing moves unless the audio plays (idle = zero frames).

const _ink = SlmColors.ivory;
const _soft = Color(0xFFC9D5E6);
const _danger = Color(0xFFFF8A80);

/// Won life skills, in the order they were won.
class LifeSkillsListPage extends ConsumerWidget {
  const LifeSkillsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final won = ref.watch(gameSaveProvider.select((s) => s.toolbox.lifeSkills));
    final modules = ref.watch(lifeSkillModulesProvider);
    return Scaffold(
      backgroundColor: SlmColors.navy950,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(title: LifeSkillLines.menu, sub: LifeSkillLines.listSub),
            Expanded(
              child: modules.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: SlmColors.gold300),
                ),
                error: (_, _) => const SizedBox.shrink(),
                data: (all) {
                  final byId = {for (final m in all) m.id: m};
                  final shown = [for (final id in won) ?byId[id]];
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _SkillTile(
                      key: ValueKey('life-skill-${shown[i].id}'),
                      module: shown[i],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => LifeSkillDetailPage(moduleId: shown[i].id)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, this.sub});

  final String title;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: _ink),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SlmText(enDigits(title), role: SlmTextRole.headline, color: _ink),
                  if (sub != null) ...[
                    const SizedBox(height: 2),
                    SlmText(sub!, role: SlmTextRole.bodySm, color: SlmColors.gold200),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillTile extends StatelessWidget {
  const _SkillTile({super.key, required this.module, required this.onTap});

  final LifeSkillModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SlmCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _Picture(module.cardAsset, width: 64, height: 64),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SlmText(module.code, role: SlmTextRole.overline, color: SlmColors.gold300),
                SlmText(enDigits(module.titleBn), role: SlmTextRole.title, color: _ink, maxLines: 2),
                const SizedBox(height: 2),
                SlmText(enDigits(module.descriptionBn), role: SlmTextRole.caption, color: _soft, maxLines: 2),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: SlmColors.gold200),
        ],
      ),
    );
  }
}

/// A bundled picture decoded at its display size (empty path = nothing).
class _Picture extends StatelessWidget {
  const _Picture(this.asset, {required this.width, this.height});

  final String asset;
  final double width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    // A lesson picture (no height given) gets a fixed 4 : 5 frame, so the page
    // never jumps while pictures load.
    final h = height ?? width * 1.25;
    if (asset.isEmpty) return SizedBox(width: width, height: height ?? 0);
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2;
    return ColoredBox(
      color: SlmColors.navy900,
      child: Image.asset(
        asset,
        width: width,
        height: h,
        cacheWidth: (width * dpr).round().clamp(64, 900),
        fit: height == null ? BoxFit.contain : BoxFit.cover,
        errorBuilder: (_, _, _) => SizedBox(width: width, height: h),
      ),
    );
  }
}

/// One won life skill: card, the narration, sections, pro tip, myth buster.
class LifeSkillDetailPage extends StatefulWidget {
  const LifeSkillDetailPage({super.key, required this.moduleId, this.repo, this.audio});

  final String moduleId;

  /// Tests: null = the shared instances.
  final LifeSkillsRepo? repo;
  final LifeSkillAudioCache? audio;

  @override
  State<LifeSkillDetailPage> createState() => _LifeSkillDetailPageState();
}

class _LifeSkillDetailPageState extends State<LifeSkillDetailPage> {
  late final LifeSkillsRepo _repo = widget.repo ?? LifeSkillsRepo.instance;
  late Future<(LifeSkillModule?, LifeSkillLesson?)> _load = _fetch();

  Future<(LifeSkillModule?, LifeSkillLesson?)> _fetch() async =>
      (await _repo.module(widget.moduleId), await _repo.lesson(widget.moduleId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SlmColors.navy950,
      body: SafeArea(
        child: FutureBuilder<(LifeSkillModule?, LifeSkillLesson?)>(
          future: _load,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2.2, color: SlmColors.gold300));
            }
            final (module, lesson) = snap.data ?? (null, null);
            if (module == null || lesson == null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Header(title: LifeSkillLines.menu),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SlmText(LifeSkillLines.loadFailed, role: SlmTextRole.body, color: _soft),
                          const SizedBox(height: 12),
                          SlmButton.gold(
                            label: LifeSkillLines.retry,
                            onPressed: () => setState(() => _load = _fetch()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return _Detail(module: module, lesson: lesson, audio: widget.audio ?? LifeSkillAudioCache.instance);
          },
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.module, required this.lesson, required this.audio});

  final LifeSkillModule module;
  final LifeSkillLesson lesson;
  final LifeSkillAudioCache audio;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width.clamp(0.0, 560.0) - 32;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Header(title: module.titleBn, sub: module.code)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          sliver: SliverList.list(
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _Picture(module.cardAsset, width: 200, height: 200),
                ),
              ),
              const SizedBox(height: 14),
              _AudioCard(key: const ValueKey('life-skill-audio'), url: module.audioUrl, cache: audio),
              if (lesson.briefing.isNotEmpty) ...[
                const SizedBox(height: 14),
                SlmText(enDigits(lesson.briefing), role: SlmTextRole.body, color: _soft),
              ],
              for (final s in lesson.sections) ...[
                const SizedBox(height: 18),
                SlmText(enDigits(s.title), role: SlmTextRole.title, color: SlmColors.gold200),
                for (final p in s.points) ...[
                  const SizedBox(height: 10),
                  _PointCard(point: p, width: w),
                ],
              ],
              if (lesson.proTips.isNotEmpty) ...[
                const SizedBox(height: 18),
                SlmCard(
                  key: const ValueKey('life-skill-pro-tip'),
                  variant: SlmCardVariant.gold,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SlmText(
                        enDigits(lesson.proTipTitle.isEmpty ? LifeSkillLines.proTip : lesson.proTipTitle),
                        role: SlmTextRole.title,
                        color: SlmColors.gold200,
                      ),
                      for (final tip in lesson.proTips) ...[
                        const SizedBox(height: 6),
                        SlmText(enDigits(tip), role: SlmTextRole.body, color: _ink),
                      ],
                    ],
                  ),
                ),
              ],
              if (lesson.myths.isNotEmpty) ...[
                const SizedBox(height: 18),
                SlmText(
                  enDigits(lesson.mythTitle.isEmpty ? LifeSkillLines.myth : lesson.mythTitle),
                  role: SlmTextRole.title,
                  color: SlmColors.gold200,
                ),
                if (lesson.mythImage.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ClipRRect(borderRadius: BorderRadius.circular(14), child: _Picture(lesson.mythImage, width: w)),
                ],
                for (final (i, m) in lesson.myths.indexed) ...[
                  const SizedBox(height: 10),
                  SlmCard(
                    key: ValueKey('life-skill-myth-$i'),
                    variant: SlmCardVariant.sunken,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.close_rounded, size: 18, color: _danger),
                            const SizedBox(width: 6),
                            Expanded(child: SlmText(enDigits(m.myth), role: SlmTextRole.body, color: _soft)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_rounded, size: 18, color: SlmColors.emerald300),
                            const SizedBox(width: 6),
                            Expanded(child: SlmText(enDigits(m.reality), role: SlmTextRole.body, color: _ink)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              if (lesson.moreFacts.isNotEmpty) ...[
                const SizedBox(height: 18),
                SlmText(enDigits(lesson.moreTitle), role: SlmTextRole.title, color: SlmColors.gold200),
                for (final (title, content) in lesson.moreFacts) ...[
                  const SizedBox(height: 8),
                  SlmText(enDigits(title), role: SlmTextRole.titleSm, color: _ink),
                  const SizedBox(height: 2),
                  SlmText(enDigits(content), role: SlmTextRole.bodySm, color: _soft),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PointCard extends StatelessWidget {
  const _PointCard({required this.point, required this.width});

  final LifeSkillPoint point;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SlmCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SlmText(enDigits(point.name), role: SlmTextRole.titleSm, color: _ink),
          if (point.image.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(12), child: _Picture(point.image, width: width - 24)),
            if (point.caption.isNotEmpty) ...[
              const SizedBox(height: 4),
              SlmText(enDigits(point.caption), role: SlmTextRole.caption, color: SlmColors.gold200),
            ],
          ],
          if (point.specifications.isNotEmpty) ...[
            const SizedBox(height: 8),
            SlmText(enDigits(point.specifications), role: SlmTextRole.body, color: _ink),
          ],
          if (point.importance.isNotEmpty) ...[
            const SizedBox(height: 6),
            SlmText(enDigits(point.importance), role: SlmTextRole.bodySm, color: _soft),
          ],
          if (point.dailyCheck.isNotEmpty) ...[
            const SizedBox(height: 6),
            SlmText(
              enDigits('${LifeSkillLines.dailyCheck}: ${point.dailyCheck}'),
              role: SlmTextRole.bodySm,
              color: SlmColors.emerald300,
            ),
          ],
        ],
      ),
    );
  }
}

/// The narration: play / pause and a progress bar. Streams the first time
/// (with a gentle note that it needs the internet once); after one full play
/// the file is saved and later plays work offline. The player is created on
/// the first tap, so an open page with no audio playing costs nothing.
class _AudioCard extends StatefulWidget {
  const _AudioCard({super.key, required this.url, required this.cache});

  final String url;
  final LifeSkillAudioCache cache;

  @override
  State<_AudioCard> createState() => _AudioCardState();
}

class _AudioCardState extends State<_AudioCard> {
  AudioPlayer? _player;
  final _subs = <StreamSubscription<Object?>>[];
  final _progress = ValueNotifier<double>(0);
  File? _saved;
  var _checked = false;
  var _playing = false;
  var _failed = false;
  var _streaming = false;
  Duration _length = Duration.zero;

  @override
  void initState() {
    super.initState();
    unawaited(_checkSaved());
  }

  Future<void> _checkSaved() async {
    final f = await widget.cache.cached(widget.url);
    if (!mounted) return;
    setState(() {
      _saved = f;
      _checked = true;
    });
  }

  @override
  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    final p = _player;
    if (p != null) unawaited(p.dispose());
    _progress.dispose();
    super.dispose();
  }

  AudioPlayer _make() {
    final p = AudioPlayer();
    _subs
      ..add(p.onDurationChanged.listen((d) => _length = d))
      ..add(p.onPositionChanged.listen((pos) {
        final ms = _length.inMilliseconds;
        if (ms > 0) _progress.value = (pos.inMilliseconds / ms).clamp(0.0, 1.0);
      }))
      ..add(p.onPlayerComplete.listen((_) {
        _progress.value = 1;
        if (mounted) setState(() => _playing = false);
        // A full streamed play: save it for offline.
        if (_streaming) {
          unawaited(widget.cache.saveAfterFullPlay(widget.url).then((ok) {
            if (ok && mounted) unawaited(_checkSaved());
          }));
        }
      }));
    return p;
  }

  Future<void> _toggle() async {
    if (widget.url.isEmpty) return;
    final p = _player ??= _make();
    if (_playing) {
      setState(() => _playing = false);
      try {
        await p.pause();
      } catch (_) {}
      return;
    }
    setState(() {
      _playing = true;
      _failed = false;
    });
    try {
      if (p.state == PlayerState.paused) {
        await p.resume();
      } else {
        final saved = _saved ?? await widget.cache.cached(widget.url);
        _streaming = saved == null;
        _progress.value = 0;
        await p.play(saved != null ? DeviceFileSource(saved.path) : UrlSource(widget.url));
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _playing = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlmCard(
      variant: SlmCardVariant.raised,
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SlmIconButton(
                key: const ValueKey('life-skill-play'),
                icon: _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                tooltip: _playing ? LifeSkillLines.pause : LifeSkillLines.listen,
                onPressed: widget.url.isEmpty ? null : () => unawaited(_toggle()),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ValueListenableBuilder<double>(
                  valueListenable: _progress,
                  builder: (_, v, _) => SlmProgressBar(value: v, tone: SlmTone.gold),
                ),
              ),
            ],
          ),
          if (_checked) ...[
            const SizedBox(height: 8),
            SlmText(
              _failed
                  ? LifeSkillLines.audioFailed
                  : _saved != null
                      ? LifeSkillLines.savedNote
                      : LifeSkillLines.offlineNote,
              key: const ValueKey('life-skill-audio-note'),
              role: SlmTextRole.caption,
              color: _failed ? _danger : _soft,
            ),
          ],
        ],
      ),
    );
  }
}
