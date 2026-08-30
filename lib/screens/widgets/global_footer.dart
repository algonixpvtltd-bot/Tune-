import 'dart:ui';
import 'package:Bloomee/blocs/player_overlay/player_overlay_cubit.dart';
import 'package:Bloomee/screens/widgets/player_overlay_wrapper.dart';
import 'package:Bloomee/screens/widgets/mini_player_widget.dart';
import 'package:Bloomee/core/theme/app_theme.dart';
import 'package:Bloomee/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:responsive_framework/responsive_framework.dart';

class GlobalFooter extends StatelessWidget {
  const GlobalFooter({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    context.watch<PlayerOverlayCubit>();
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return PlayerOverlayWrapper(
      child: BackButtonListener(
        // FIX H-04: Back button priority order:
        // ① Navigator routes (FullscreenLyricsView, PlayerSettings, TimerView, etc.)
        // ② UpNext panel collapse
        // ③ Player overlay hide
        // ④ GoRouter shell navigation
        // ⑤ System exit
        //
        // Previously the handler short-circuited at step ③ whenever the player
        // was visible, swallowing Navigator pops and causing sub-screens to
        // appear orphaned over a hidden/collapsed player.
        onBackButtonPressed: () async {
          final overlayC = context.read<PlayerOverlayCubit>();
          final router = GoRouter.of(context);

          // ① Navigator MUST have first priority — always.
          if (router.canPop()) {
            router.pop();
            return true;
          }

          // ② Collapse UpNext panel if expanded (player must be visible).
          if (overlayC.state && overlayC.collapseUpNextPanel()) {
            return true;
          }

          // ③ Hide the player overlay.
          if (overlayC.state) {
            overlayC.hidePlayer();
            return true;
          }

          // ④ Let PopScope handle tab/exit navigation below.
          return false;
        },
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            await _handleHardwareBackPress(context);
          },
          child: Scaffold(
            backgroundColor: Default_Theme.themeColor,
            drawerScrimColor: Default_Theme.themeColor,
            body: _AnimatedPageView(navigationShell: navigationShell),
            bottomNavigationBar: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MiniPlayerWidget(),
                  GlassDockNavBar(navigationShell: navigationShell),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handles PopScope back presses using the same priority order as
  /// BackButtonListener above.
  Future<void> _handleHardwareBackPress(BuildContext context) async {
    final overlayC = context.read<PlayerOverlayCubit>();
    final router = GoRouter.of(context);

    // ① Navigator routes first
    if (router.canPop()) {
      router.pop();
      return;
    }

    // ② Collapse UpNext panel
    if (overlayC.state && overlayC.collapseUpNextPanel()) return;

    // ③ Hide player
    if (overlayC.state) {
      overlayC.hidePlayer();
      return;
    }

    // ④ Navigate to home tab
    if (navigationShell.currentIndex != 0) {
      navigationShell.goBranch(0);
      return;
    }

    // ⑤ Exit app
    if (context.mounted) {
      await SystemNavigator.pop();
    }
  }
}

class _AnimatedPageView extends StatefulWidget {
  const _AnimatedPageView({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  State<_AnimatedPageView> createState() => _AnimatedPageViewState();
}

class _AnimatedPageViewState extends State<_AnimatedPageView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.navigationShell.currentIndex;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(_AnimatedPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell.currentIndex != _previousIndex) {
      _previousIndex = widget.navigationShell.currentIndex;
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.navigationShell,
      ),
    );
  }
}

class VerticalTextNavBar extends StatelessWidget {
  const VerticalTextNavBar({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      _NavBarItem(label: l10n.navHome, index: 0),
      _NavBarItem(label: l10n.navLibrary, index: 1),
      _NavBarItem(label: l10n.navSearch, index: 2),
      _NavBarItem(label: l10n.navLocal, index: 3),
      _NavBarItem(label: l10n.navOffline, index: 4),
    ];

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 52,
        margin: const EdgeInsets.fromLTRB(10, 0, 4, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...items.map((item) {
                    final isSelected = navigationShell.currentIndex == item.index;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => navigationShell.goBranch(item.index),
                        child: RotatedBox(
                          quarterTurns: 3, // Rotates 270 degrees counter-clockwise (reads upwards)
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 180),
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.35),
                                  letterSpacing: 1.5,
                                ),
                                child: Text(item.label.toUpperCase()),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1DB954), // Glowing neon-green dot
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF1DB954),
                                        blurRadius: 6,
                                        spreadRadius: 1.5,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem {
  final String label;
  final int index;
  const _NavBarItem({required this.label, required this.index});
}

class GlassDockNavBar extends StatelessWidget {
  const GlassDockNavBar({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = navigationShell.currentIndex;
    final items = [
      _DockItem(icon: MingCuteIcons.mgc_home_4_fill, index: 0),
      _DockItem(icon: MingCuteIcons.mgc_book_5_fill, index: 1),
      _DockItem(icon: MingCuteIcons.mgc_search_2_fill, index: 2),
      _DockItem(icon: MingCuteIcons.mgc_music_2_fill, index: 3),
      _DockItem(icon: MingCuteIcons.mgc_folder_download_fill, index: 4),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double dockWidth = constraints.maxWidth;
        const double paddingHorizontal = 16.0;
        final double usableWidth = dockWidth - (paddingHorizontal * 2);
        final double itemWidth = usableWidth / 5;
        const double bubbleWidth = 46.0;
        const double bubbleHeight = 38.0;
        const double dockHeight = 62.0;

        final bubbleLeft = paddingHorizontal +
            (selectedIndex * itemWidth) +
            (itemWidth - bubbleWidth) / 2;

        return Container(
          width: dockWidth,
          height: dockHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0F0B), // Solid theme dark background
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1.0,
              ),
            ),
          ),
          child: Stack(
            children: [
              // ── Animated Liquid/Bubble Background ──
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack, // Gives a slight organic bounce to the bubble!
                left: bubbleLeft,
                top: (dockHeight - bubbleHeight - 2) / 2, // Vertically center the bubble inside container
                width: bubbleWidth,
                height: bubbleHeight,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1DB954),
                        Color(0xFF0D7A35),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1DB954).withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                ),
              ),
              // ── Row of Icons ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: paddingHorizontal),
                child: Row(
                  children: items.map((item) {
                    final isSelected = selectedIndex == item.index;
                    final icon = item.icon;

                    return SizedBox(
                      width: itemWidth,
                      height: dockHeight,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => navigationShell.goBranch(item.index),
                        child: Center(
                          child: AnimatedScale(
                            scale: isSelected ? 1.15 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            child: Icon(
                              icon,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                              size: 23,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DockItem {
  final IconData icon;
  final int index;
  const _DockItem({
    required this.icon,
    required this.index,
  });
}

