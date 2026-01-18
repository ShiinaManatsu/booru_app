import 'dart:ui';
import 'dart:async';

import 'package:booru_app/models/rx/booru_api.dart';
import 'package:booru_app/pages/home/post_feed.dart';
import 'package:booru_app/pages/search/search_page.dart';
import 'package:booru_app/pages/settings/settings_screen.dart';
import 'package:booru_app/settings/app_settings.dart';
import 'package:booru_app/settings/language.dart';
import 'package:booru_app/main.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  bool _showSwitchOverlay = false;
  Timer? _switchOverlayTimer;
  late ClientType _overlayClient;
  late final VoidCallback _clientListener;

  @override
  void initState() {
    super.initState();

    _overlayClient = AppSettings.currentClient;
    _clientListener = _handleClientChanged;
    AppSettings.currentClientListenable.addListener(_clientListener);
  }

  void _handleClientChanged() {
    if (!mounted) return;
    setState(() {
      _overlayClient = AppSettings.currentClientListenable.value;
      _showSwitchOverlay = true;
    });

    _switchOverlayTimer?.cancel();
    _switchOverlayTimer = Timer(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      setState(() => _showSwitchOverlay = false);
    });
  }

  late final Widget _searchTab = SearchPage(
    key: const PageStorageKey('tab_search'),
    booruApi: booruApi,
  );

  late final Widget _settingsTab = const SettingsScreen(
    key: PageStorageKey('tab_settings'),
  );

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _TabSpec(
        label: language.content.posts,
        icon: FontAwesomeIcons.images,
        child: ValueListenableBuilder<ClientType>(
          valueListenable: AppSettings.currentClientListenable,
          builder: (context, client, _) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: Tween(begin: 0.995, end: 1.0).animate(anim), child: child),
              ),
              child: PostFeed(
                key: PageStorageKey('tab_posts_${client.name}'),
                title: 'posts',
                initialFetchType: FetchType.Posts,
                booruApi: booruApi,
              ),
            );
          },
        ),
      ),
      _TabSpec(
        label: language.content.popularPosts,
        icon: FontAwesomeIcons.fireFlameCurved,
        child: ValueListenableBuilder<ClientType>(
          valueListenable: AppSettings.currentClientListenable,
          builder: (context, client, _) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: Tween(begin: 0.995, end: 1.0).animate(anim), child: child),
              ),
              child: PopularFeed(
                key: ValueKey('tab_popular_${client.name}'),
                booruApi: booruApi,
                client: client,
              ),
            );
          },
        ),
      ),
      _TabSpec(
        label: language.content.search,
        icon: FontAwesomeIcons.magnifyingGlass,
        child: _searchTab,
      ),
      _TabSpec(
        label: language.content.settings,
        icon: FontAwesomeIcons.gear,
        child: _settingsTab,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(
              index: _index,
              children: [for (final t in tabs) t.child],
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_showSwitchOverlay,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 140),
                  opacity: _showSwitchOverlay ? 1 : 0,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.black.withAlpha((0.18 * 255).round()),
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.only(top: 14),
                        child: _SwitchingPill(client: _overlayClient),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: _BottomNav(
                tabs: tabs,
                index: _index,
                onChanged: (i) => setState(() => _index = i),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _switchOverlayTimer?.cancel();
    AppSettings.currentClientListenable.removeListener(_clientListener);
    super.dispose();
  }
}

class _SwitchingPill extends StatelessWidget {
  const _SwitchingPill({required this.client});

  final ClientType client;

  @override
  Widget build(BuildContext context) {
    final text = switch (client) {
      ClientType.Yande => 'Switching to yande.re…',
      ClientType.Konachan => 'Switching to konachan.com…',
    };
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.45 * 255).round()),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withAlpha((0.12 * 255).round()),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _TabSpec {
  _TabSpec({required this.label, required this.icon, required this.child});
  final String label;
  final IconData icon;
  final Widget child;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.tabs,
    required this.index,
    required this.onChanged,
  });

  final List<_TabSpec> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: Colors.black.withAlpha((0.35 * 255).round()),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < tabs.length; i++)
                  _NavItem(
                    label: tabs[i].label,
                    icon: tabs[i].icon,
                    selected: i == index,
                    onTap: () => onChanged(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? ShadTheme.of(context).colorScheme.primary : Colors.white70;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withAlpha((0.08 * 255).round()) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class PopularFeed extends StatefulWidget {
  const PopularFeed({super.key, required this.booruApi, required this.client});

  final BooruAPI booruApi;
  final ClientType client;

  @override
  State<PopularFeed> createState() => _PopularFeedState();
}

class _PopularFeedState extends State<PopularFeed> {
  Period _period = Period.Week;

  static const double _topBarHeight = 48;
  static const double _topBarMarginTop = 12;
  static const double _topBarPadding = 8;

  @override
  Widget build(BuildContext context) {
    final FetchType type = switch (_period) {
      Period.None => FetchType.PopularByDay,
      Period.Week => FetchType.PopularByWeek,
      Period.Month => FetchType.PopularByMonth,
      // No popular_by_year endpoint; keep the original recent-year behavior.
      Period.Year => FetchType.PopularRecent,
    };

    final topInset = _topBarMarginTop + _topBarHeight + 12;
    return Stack(
      children: [
        Positioned.fill(
          child: PostFeed(
            key: ValueKey('popular_${widget.client.name}_$type-$_period'),
            title: language.content.popularPosts,
            initialFetchType: type,
            booruApi: widget.booruApi,
            period: type == FetchType.PopularRecent ? _period : null,
            gridPadding: EdgeInsets.fromLTRB(12, topInset, 12, 100),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: _topBarMarginTop,
          child: _GlassPeriodBar(
            height: _topBarHeight,
            padding: _topBarPadding,
            period: _period,
            onChanged: (p) => setState(() => _period = p),
          ),
        ),
      ],
    );
  }
}

class _GlassPeriodBar extends StatelessWidget {
  const _GlassPeriodBar({
    required this.height,
    required this.padding,
    required this.period,
    required this.onChanged,
  });

  final double height;
  final double padding;
  final Period period;
  final ValueChanged<Period> onChanged;

  @override
  Widget build(BuildContext context) {
    final entries = [
      MapEntry(Period.None, language.content.last24h),
      MapEntry(Period.Week, language.content.week),
      MapEntry(Period.Month, language.content.month),
      MapEntry(Period.Year, language.content.year),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: height,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha((0.30 * 255).round()),
            border: Border.all(
              color: Colors.white.withAlpha((0.10 * 255).round()),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              for (final e in entries)
                Expanded(
                  child: _PeriodItem(
                    label: e.value,
                    selected: e.key == period,
                    onTap: () => onChanged(e.key),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodItem extends StatelessWidget {
  const _PeriodItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ShadTheme.of(context).colorScheme;
    final fg = selected ? colorScheme.foreground : Colors.white70;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white.withAlpha((0.12 * 255).round()) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: fg,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
