import 'dart:async';
import 'dart:ui';

import 'package:booru_app/models/rx/task_bloc.dart';
import 'package:booru_app/settings/app_settings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;

class DownloadOverlay extends StatefulWidget {
  const DownloadOverlay({super.key, required this.taskBloc, this.bottomPadding = 92});

  final TaskBloc taskBloc;

  /// Leave room for the bottom nav.
  final double bottomPadding;

  @override
  State<DownloadOverlay> createState() => _DownloadOverlayState();
}

class _DownloadOverlayState extends State<DownloadOverlay> {
  static const _panelWidth = 360.0;
  static const _panelMaxHeight = 320.0;
  static const _panelAnimDuration = Duration(milliseconds: 220);
  static const _rowAnimDuration = Duration(milliseconds: 220);
  static const _maxVisible = 6;

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<DownloadTask> _tasks = <DownloadTask>[];
  StreamSubscription<List<DownloadTask>>? _sub;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _sub = widget.taskBloc.tasks.listen(_onTasks);
  }

  @override
  void didUpdateWidget(covariant DownloadOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.taskBloc != widget.taskBloc) {
      _sub?.cancel();
      _tasks.clear();
      _totalCount = 0;
      _sub = widget.taskBloc.tasks.listen(_onTasks);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onTasks(List<DownloadTask> incoming) {
    if (!mounted) return;

    _totalCount = incoming.length;
    final desired = incoming.length > _maxVisible ? incoming.sublist(incoming.length - _maxVisible) : incoming;

    final listState = _listKey.currentState;
    if (listState == null) {
      // First frame: sync without animations.
      _tasks
        ..clear()
        ..addAll(desired);
      setState(() {});
      return;
    }

    final desiredIds = desired.map((t) => t.post.id).toSet();

    // Remove items not in desired.
    for (var i = _tasks.length - 1; i >= 0; i--) {
      final t = _tasks[i];
      if (!desiredIds.contains(t.post.id)) {
        final removed = _tasks.removeAt(i);
        listState.removeItem(
          i,
          (context, animation) => _buildAnimatedRow(context, removed, animation, isRemoving: true),
          duration: _rowAnimDuration,
        );
      }
    }

    // Insert new items (best-effort order; downloads are append-only normally).
    for (var i = 0; i < desired.length; i++) {
      final d = desired[i];
      final exists = _tasks.any((t) => t.post.id == d.post.id);
      if (!exists) {
        final insertIndex = i.clamp(0, _tasks.length);
        _tasks.insert(insertIndex, d);
        listState.insertItem(insertIndex, duration: _rowAnimDuration);
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Keep the Positioned node stable in the tree.
    // NOTE: Don't use AnimatedSwitcher here because it keeps the old+new children
    // alive during the transition, which would duplicate our AnimatedList GlobalKey.
    final show = _tasks.isNotEmpty;
    return Positioned(
      right: 16,
      bottom: widget.bottomPadding,
      child: IgnorePointer(
        ignoring: !show,
        child: ExcludeSemantics(
          excluding: !show,
          child: AnimatedSlide(
            duration: _panelAnimDuration,
            curve: Curves.easeOutCubic,
            offset: show ? Offset.zero : const Offset(0.10, 0.10),
            child: AnimatedOpacity(
              duration: _panelAnimDuration,
              curve: Curves.easeOutCubic,
              opacity: show ? 1 : 0,
              child: _buildPanel(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: _panelWidth,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Material(
            color: Colors.black.withValues(alpha: 0.45),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: _panelMaxHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Downloads ($_totalCount)',
                      style: theme.textTheme.titleSmall?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: AnimatedList(
                        key: _listKey,
                        initialItemCount: _tasks.length,
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index, animation) {
                          final t = _tasks[index];
                          return _buildAnimatedRow(context, t, animation);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedRow(BuildContext context, DownloadTask task, Animation<double> animation, {bool isRemoving = false}) {
    final fade = CurvedAnimation(parent: animation, curve: isRemoving ? Curves.easeIn : Curves.easeOut);
    return SizeTransition(
      sizeFactor: fade,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: fade,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _TaskCard(
            task: task,
            onCancel: () => widget.taskBloc.cancelTask.add(task),
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.onCancel});

  final DownloadTask task;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = task.isDownloaded;
    final isCancelled = task.canceled;

    final bg = isCancelled
        ? Colors.red.withValues(alpha: 0.10)
        : isDone
            ? Colors.green.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.06);

    final border = isCancelled
        ? Colors.red.withValues(alpha: 0.25)
        : isDone
            ? Colors.green.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.10);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: DefaultTextStyle(
        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white) ?? const TextStyle(color: Colors.white),
        child: _TaskRow(task: task, onCancel: onCancel),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.onCancel});

  final DownloadTask task;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final label = _labelFor(task);
    final progress = task.progress;
    final canCancel = !task.isDownloaded && !task.canceled;
    final status = task.canceled
        ? 'Cancelled'
        : task.isDownloaded
            ? 'Done'
            : progress == null
                ? 'Downloading'
                : '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%';

    final progressValue = task.canceled
        ? null
        : task.isDownloaded
            ? 1.0
            : progress;

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 42,
            height: 42,
            child: CachedNetworkImage(
              imageUrl: AppSettings.previewQuality == PreviewQuality.Medium ? (task.post.sampleUrl ?? task.post.previewUrl) : task.post.previewUrl,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 120),
              errorWidget: (context, url, error) => Container(
                color: Colors.white.withValues(alpha: 0.06),
                child: const Icon(Icons.image_not_supported, color: Colors.white54, size: 18),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 2),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                child: Text(
                  status,
                  key: ValueKey(status),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: (progressValue == null)
                    ? LinearProgressIndicator(
                        value: null,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.85)),
                      )
                    : TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(end: progressValue.clamp(0, 1)),
                        builder: (context, v, _) {
                          return LinearProgressIndicator(
                            value: v,
                            minHeight: 6,
                            backgroundColor: Colors.white.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.85)),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) {
            return FadeTransition(
              opacity: anim,
              child: SizeTransition(
                sizeFactor: anim,
                axis: Axis.horizontal,
                child: child,
              ),
            );
          },
          child: canCancel
              ? IconButton(
                  key: ValueKey('cancel_${task.post.id}'),
                  tooltip: 'Cancel',
                  onPressed: onCancel,
                  icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                )
              : (task.filePath != null && task.filePath!.trim().isNotEmpty)
                  ? IconButton(
                      key: ValueKey('open_${task.post.id}'),
                      tooltip: 'Open',
                      onPressed: () => OpenFile.open(task.filePath!),
                      icon: const Icon(Icons.open_in_new, color: Colors.white70, size: 18),
                    )
                  : const SizedBox(key: ValueKey('spacer'), width: 40),
        ),
      ],
    );
  }

  String _labelFor(DownloadTask t) {
    if (t.filePath != null && t.filePath!.trim().isNotEmpty) {
      return p.basename(t.filePath!);
    }
    return 'post_${t.post.id}';
  }
}
