import 'dart:developer';
import 'package:Bloomee/blocs/explore/cubit/explore_cubits.dart';
import 'package:Bloomee/blocs/internet_connectivity/cubit/connectivity_cubit.dart';
import 'package:Bloomee/blocs/lastdotfm/lastdotfm_cubit.dart';
import 'package:Bloomee/blocs/media_player/bloomee_player_cubit.dart';
import 'package:Bloomee/blocs/notification/notification_cubit.dart';
import 'package:Bloomee/blocs/settings_cubit/cubit/settings_cubit.dart';
import 'package:Bloomee/core/di/service_locator.dart';
import 'package:Bloomee/core/models/exported.dart';
import 'package:Bloomee/core/models/media_playlist_model.dart';
import 'package:Bloomee/plugins/blocs/content/content_bloc.dart';
import 'package:Bloomee/plugins/blocs/content/content_event.dart';
import 'package:Bloomee/plugins/blocs/content/content_state.dart';
import 'package:Bloomee/plugins/blocs/plugin/plugin_bloc.dart';
import 'package:Bloomee/plugins/blocs/plugin/plugin_state.dart';
import 'package:Bloomee/screens/screen/home_views/recents_view.dart';
import 'package:Bloomee/screens/screen/home_views/setting_views/about.dart';
import 'package:Bloomee/screens/widgets/more_bottom_sheet.dart';
import 'package:Bloomee/screens/widgets/sign_board_widget.dart';
import 'package:Bloomee/screens/widgets/song_tile.dart';
import 'package:Bloomee/utils/load_image.dart';
import 'package:flutter/material.dart';
import 'package:Bloomee/screens/screen/home_views/notification_view.dart';
import 'package:Bloomee/screens/screen/home_views/setting_view.dart';
import 'package:Bloomee/screens/screen/home_views/timer_view.dart';
import 'package:Bloomee/core/theme/app_theme.dart';
import 'package:Bloomee/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'chart/carousal_widget.dart';
import '../widgets/horizontal_card_view.dart';
import '../widgets/tab_list_widget.dart';
import '../widgets/square_card.dart';
import 'package:Bloomee/src/rust/api/plugin/commands.dart';
import 'package:badges/badges.dart' as badges;

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  bool isUpdateChecked = false;
  late final ContentBloc _homeContentBloc;
  Future<List<Track>> lFMData = Future.value(const []);

  @override
  void initState() {
    super.initState();
    _homeContentBloc = ContentBloc(pluginService: ServiceLocator.pluginService);
    _tryLoadHomeSections();
  }

  /// Only loads home sections when both settings are ready and plugins are loaded.
  void _tryLoadHomeSections() {
    final settingsState = context.read<SettingsCubit>().state;
    if (!settingsState.settingsReady) return;

    final pluginState = context.read<PluginBloc>().state;
    final contentResolvers = pluginState.loadedContentResolvers;
    if (contentResolvers.isEmpty) return;

    final preferredId = settingsState.homePluginId;
    // If the user's preferred plugin is installed but not yet loaded, wait for it.
    // This prevents flashing the wrong plugin's home page on startup.
    if (preferredId.isNotEmpty) {
      final isAlreadyLoaded =
          contentResolvers.any((p) => p.manifest.id == preferredId);
      if (!isAlreadyLoaded) {
        final isInstalled = pluginState.availablePlugins
            .any((p) => p.manifest.id == preferredId);
        if (isInstalled) return; // Preferred plugin is loading — wait for it
      }
    }

    final pluginId = _effectiveHomePluginId(contentResolvers);

    // Don't reload if we're already showing content from this plugin.
    if (_homeContentBloc.state.activePluginId == pluginId &&
        _homeContentBloc.state.homeSections != null) {
      return;
    }

    _homeContentBloc.add(GetHomeSections(pluginId: pluginId));
  }

  String _effectiveHomePluginId(List<dynamic> loadedResolvers) {
    final preferredId = context.read<SettingsCubit>().state.homePluginId;
    final hasPreferred = preferredId.isNotEmpty &&
        loadedResolvers.any((plugin) => plugin.manifest.id == preferredId);
    return hasPreferred ? preferredId : loadedResolvers.first.manifest.id;
  }

  @override
  void dispose() {
    _homeContentBloc.close();
    super.dispose();
  }

  Future<List<Track>> fetchLFMPicks(bool state, BuildContext ctx) async {
    if (state) {
      try {
        final data = await lFMData;
        if (data.isNotEmpty) return data;
        if (ctx.mounted) {
          final pluginState = ctx.read<PluginBloc>().state;
          final priority = ctx.read<SettingsCubit>().state.resolverPriority;
          final allIds = pluginState.loadedContentResolvers
              .map((p) => p.manifest.id)
              .toList();
          final resolverIds = [
            ...priority.where(allIds.contains),
            ...allIds.where((id) => !priority.contains(id)),
          ];
          lFMData = ctx.read<LastdotfmCubit>().getRecommendedTracks(
                resolverPluginIds: resolverIds,
              );
        }
        return (await lFMData);
      } catch (e) {
        log(e.toString(), name: "ExploreScreen");
      }
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: MultiBlocListener(
        listeners: [
          BlocListener<SettingsCubit, SettingsState>(
            listenWhen: (previous, current) =>
                previous.homePluginId != current.homePluginId ||
                (!previous.settingsReady && current.settingsReady),
            listener: (context, state) {
              _homeContentBloc.add(const ClearHomeSections());
              _tryLoadHomeSections();
            },
          ),
          BlocListener<PluginBloc, PluginState>(
            listenWhen: (previous, current) {
              return previous.loadedContentResolvers !=
                      current.loadedContentResolvers ||
                  previous.loadedPluginIds != current.loadedPluginIds;
            },
            listener: (context, state) {
              if (state.loadedContentResolvers.isEmpty) {
                _homeContentBloc.add(const ClearHomeSections());
                return;
              }

              final activePluginId = _homeContentBloc.state.activePluginId;
              if (activePluginId != null &&
                  !state.loadedPluginIds.contains(activePluginId)) {
                // Active plugin was unloaded — reload from preferred.
                _homeContentBloc.add(const ClearHomeSections());
                _tryLoadHomeSections();
                return;
              }

              // Plugin list changed — check if preferred plugin is different.
              _tryLoadHomeSections();
            },
          ),
        ],
        child: Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              final pluginId = _effectiveHomePluginId(
                context.read<PluginBloc>().state.loadedContentResolvers,
              );
              _homeContentBloc.add(
                GetHomeSections(pluginId: pluginId, bypassCache: true),
              );
            },
            child: CustomScrollView(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              slivers: [
                const CustomDiscoverBar(),
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      if (isAndroidPlatform)
                        const _SpotifyQuickAccessGrid(),
                      const CaraouselWidget(),
                      if (isAndroidPlatform)
                        const _TamilHitsRow(),
                      if (isAndroidPlatform)
                        const _MalayalamHitsRow(),
                      if (!isAndroidPlatform)
                        Padding(
                          padding: const EdgeInsets.only(top: 15.0),
                          child: SizedBox(
                            child: BlocBuilder<RecentlyCubit, RecentlyCubitState>(
                              builder: (context, state) {
                                if (state is RecentlyCubitInitial) {
                                  return const Center(
                                    child: SizedBox(
                                      height: 60,
                                      width: 60,
                                      child: CircularProgressIndicator(
                                        color: Default_Theme.accentColor2,
                                      ),
                                    ),
                                  );
                                }
                                if (state.tracks.isNotEmpty) {
                                  return InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const HistoryView(),
                                        ),
                                      );
                                    },
                                    child: TabSongListWidget(
                                      list: state.tracks.map((e) {
                                        return SongCardWidget(
                                          song: e,
                                          onTap: () {
                                            context
                                                .read<BloomeePlayerCubit>()
                                                .bloomeePlayer
                                                .loadPlaylist(
                                                  Playlist(
                                                    tracks: state.tracks,
                                                    title: 'Recently',
                                                  ),
                                                  idx: state.tracks.indexOf(e),
                                                  doPlay: true,
                                                );
                                          },
                                          onOptionsTap: () => showMoreBottomSheet(
                                            context,
                                            e,
                                            showSinglePlay: true,
                                          ),
                                        );
                                      }).toList(),
                                      category: AppLocalizations.of(context)!
                                          .exploreRecently,
                                      columnSize: 3,
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                        ),
                      BlocBuilder<SettingsCubit, SettingsState>(
                        builder: (context, state) {
                          if (state.lFMPicks) {
                            return FutureBuilder(
                              future: fetchLFMPicks(state.lFMPicks, context),
                              builder: (context, snapshot) {
                                if (snapshot.hasData &&
                                    (snapshot.data?.isNotEmpty ?? false)) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 15.0),
                                    child: TabSongListWidget(
                                      list: snapshot.data!.map((e) {
                                        return SongCardWidget(
                                          song: e,
                                          onTap: () {
                                            context
                                                .read<BloomeePlayerCubit>()
                                                .bloomeePlayer
                                                .loadPlaylist(
                                                  Playlist(
                                                    tracks: snapshot.data!,
                                                    title: 'Last.Fm Picks',
                                                  ),
                                                  idx:
                                                      snapshot.data!.indexOf(e),
                                                  doPlay: true,
                                                );
                                          },
                                          onOptionsTap: () =>
                                              showMoreBottomSheet(
                                                  context,
                                                  showSinglePlay: true,
                                                  e),
                                        );
                                      }).toList(),
                                      category: AppLocalizations.of(context)!
                                          .exploreLastFmPicks,
                                      columnSize: 3,
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      // Home sections from plugin
                      BlocBuilder<ContentBloc, ContentState>(
                        bloc: _homeContentBloc,
                        builder: (context, state) {
                          final loadedResolvers = context
                              .read<PluginBloc>()
                              .state
                              .loadedContentResolvers;
                          if (loadedResolvers.isEmpty) {
                            return const SignBoardWidget(
                              message:
                                  'No content plugin loaded.\nLoad a Content Resolver in Plugin Manager.',
                              icon: MingCuteIcons.mgc_plugin_2_line,
                            );
                          }

                          final sections = state.homeSections ?? const [];
                          final hasSections = sections.isNotEmpty;
                          final activePluginId = state.activePluginId;
                          if (activePluginId != null &&
                              !context
                                  .read<PluginBloc>()
                                  .state
                                  .loadedPluginIds
                                  .contains(activePluginId) &&
                              !hasSections) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: SignBoardWidget(
                                message:
                                    'Refreshing Discover source...\nThe previous source is no longer available.',
                                icon: MingCuteIcons.mgc_warning_line,
                              ),
                            );
                          }

                          if (state.homeSectionsStatus ==
                              DetailStatus.loading) {
                            if (hasSections) {
                              return _HomeSectionsList(
                                sections: sections,
                                contentBloc: _homeContentBloc,
                                state: state,
                              );
                            }

                            return BlocBuilder<ConnectivityCubit,
                                ConnectivityState>(
                              builder: (context, connState) {
                                if (connState ==
                                    ConnectivityState.disconnected) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: SignBoardWidget(
                                      message: 'No Internet Connection!',
                                      icon: MingCuteIcons.mgc_wifi_off_line,
                                    ),
                                  );
                                }

                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Default_Theme.accentColor2,
                                    ),
                                  ),
                                );
                              },
                            );
                          }

                          if (state.homeSectionsStatus == DetailStatus.error) {
                            if (hasSections) {
                              return _HomeSectionsList(
                                sections: sections,
                                contentBloc: _homeContentBloc,
                                state: state,
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: SignBoardWidget(
                                message: state.error ??
                                    'Failed to load home sections.',
                                icon: MingCuteIcons.mgc_sweats_line,
                              ),
                            );
                          }

                          if (!hasSections) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: SizedBox.shrink(),
                            );
                          }

                          return _HomeSectionsList(
                            sections: sections,
                            contentBloc: _homeContentBloc,
                            state: state,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Default_Theme.themeColor,
        ),
      ),
    );
  }
}

class _HomeSectionsList extends StatelessWidget {
  final List<Section> sections;
  final ContentBloc contentBloc;
  final ContentState state;

  const _HomeSectionsList({
    required this.sections,
    required this.contentBloc,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemExtent: 275,
      padding: const EdgeInsets.only(top: 0),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        return HorizontalCardView(
          section: section,
          pluginId: contentBloc.state.activePluginId ?? '',
          canLoadMore: section.moreLink != null,
          isLoadingMore: state.isHomeSectionLoading(section.id),
          onLoadMore: section.moreLink == null
              ? null
              : () {
                  contentBloc.add(
                    LoadMoreHomeSectionItems(
                      pluginId: contentBloc.state.activePluginId ?? '',
                      sectionId: section.id,
                      moreLink: section.moreLink!,
                    ),
                  );
                },
        );
      },
    );
  }
}

class CustomDiscoverBar extends StatelessWidget {
  const CustomDiscoverBar({super.key});

  @override
  Widget build(BuildContext context) {
    if (!isAndroidPlatform) {
      return SliverAppBar(
        floating: true,
        surfaceTintColor: Default_Theme.themeColor,
        backgroundColor: Default_Theme.themeColor,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tune',
              style: Default_Theme.primaryTextStyle.merge(
                const TextStyle(
                  fontSize: 36,
                  color: Default_Theme.accentColor2,
                ),
              ),
            ),
            const Spacer(),
            const NotificationIcon(),
            const SiteIcon(),
            const TimerIcon(),
            const SettingsIcon(),
          ],
        ),
      );
    }

    // Android: Spotify-style greeting header
    return _AndroidSpotifyHeader();
  }
}

class _AndroidSpotifyHeader extends StatefulWidget {
  @override
  State<_AndroidSpotifyHeader> createState() => _AndroidSpotifyHeaderState();
}

class _AndroidSpotifyHeaderState extends State<_AndroidSpotifyHeader> {
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    const spotifyGreen = Color(0xFF1DB954);
    const spotifyBg = Color(0xFF0A0F0B);

    return SliverAppBar(
      floating: false,
      pinned: false,
      snap: false,
      expandedHeight: 125,
      surfaceTintColor: spotifyBg,
      backgroundColor: spotifyBg,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: spotifyBg,
          padding: const EdgeInsets.fromLTRB(20, 10, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: Logo + Greeting + Actions ──────────────────
              Row(
                children: [
                  // Logo pill
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: spotifyGreen,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.music_note_rounded,
                        color: Colors.black,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          fontFamily: 'ReThink-Sans',
                          fontSize: 11,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      BlocBuilder<SettingsCubit, SettingsState>(
                        buildWhen: (prev, curr) => prev.profileName != curr.profileName,
                        builder: (context, state) {
                          return Text(
                            state.profileName,
                            style: const TextStyle(
                              fontFamily: 'Unageo',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const Spacer(),
                  const NotificationIcon(),
                  const TimerIcon(),
                  const SettingsIcon(),
                ],
              ),
              const SizedBox(height: 14),
              // ── Row 2: Bold heading ──────────────────────────────
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Ready to ',
                      style: TextStyle(
                        fontFamily: 'Unageo',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    TextSpan(
                      text: 'Vibe?',
                      style: TextStyle(
                        fontFamily: 'Unageo',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: spotifyGreen,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // ── Row 3: Subtitle ──────────────────────────────────
              const Text(
                'Explore playlists, artists, and new releases.',
                style: TextStyle(
                  fontFamily: 'ReThink-Sans',
                  fontSize: 12,
                  color: Color(0xFFB3B3B3),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationIcon extends StatelessWidget {
  const NotificationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        if (state is NotificationInitial || state.notifications.isEmpty) {
          return IconButton(
            padding: const EdgeInsets.all(5),
            constraints: const BoxConstraints(),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationView(),
                ),
              );
            },
            icon: Icon(
              isAndroidPlatform
                  ? Icons.notifications_none_rounded
                  : MingCuteIcons.mgc_notification_line,
              color: Default_Theme.primaryColor1,
              size: 30.0,
            ),
          );
        }
        return badges.Badge(
          badgeContent: Padding(
            padding: const EdgeInsets.all(1.5),
            child: Text(
              state.notifications.length.toString(),
              style: Default_Theme.primaryTextStyle.merge(
                const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Default_Theme.primaryColor2,
                ),
              ),
            ),
          ),
          badgeStyle: const badges.BadgeStyle(
            badgeColor: Default_Theme.accentColor2,
            shape: badges.BadgeShape.circle,
          ),
          position: badges.BadgePosition.topEnd(top: -10, end: -5),
          child: IconButton(
            padding: const EdgeInsets.all(5),
            constraints: const BoxConstraints(),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationView(),
                ),
              );
            },
            icon: Icon(
              isAndroidPlatform
                  ? Icons.notifications_rounded
                  : MingCuteIcons.mgc_notification_line,
              color: Default_Theme.primaryColor1,
              size: 30.0,
            ),
          ),
        );
      },
    );
  }
}

class TimerIcon extends StatelessWidget {
  const TimerIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: const EdgeInsets.all(5),
      constraints: const BoxConstraints(),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TimerView()),
        );
      },
      icon: Icon(
        isAndroidPlatform
            ? Icons.alarm_rounded
            : MingCuteIcons.mgc_stopwatch_line,
        color: Default_Theme.primaryColor1,
        size: 30.0,
      ),
    );
  }
}

class SettingsIcon extends StatelessWidget {
  const SettingsIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: const EdgeInsets.all(5),
      constraints: const BoxConstraints(),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsView()),
        );
      },
      icon: Icon(
        isAndroidPlatform
            ? Icons.settings_suggest_rounded
            : MingCuteIcons.mgc_settings_3_line,
        color: Default_Theme.primaryColor1,
        size: 30.0,
      ),
    );
  }
}

class SiteIcon extends StatelessWidget {
  const SiteIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: const EdgeInsets.all(5),
      constraints: const BoxConstraints(),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const About()),
        );
      },
      icon: const Icon(
        MingCuteIcons.mgc_flower_4_fill,
        color: Default_Theme.primaryColor1,
        size: 28.0,
      ),
    );
  }
}

class _SpotifyQuickAccessGrid extends StatelessWidget {
  const _SpotifyQuickAccessGrid();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecentlyCubit, RecentlyCubitState>(
      builder: (context, state) {
        if (state.tracks.isEmpty) return const SizedBox.shrink();
        final tracks = state.tracks.take(6).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recently Played',
                    style: TextStyle(
                      fontFamily: 'Unageo',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryView(),
                        ),
                      );
                    },
                    child: const Text(
                      'Show all',
                      style: TextStyle(
                        fontFamily: 'ReThink-Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1DB954),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.7,
                ),
                itemCount: tracks.length,
                itemBuilder: (context, idx) {
                  final track = tracks[idx];
                  return GestureDetector(
                    onTap: () {
                      context.read<BloomeePlayerCubit>().bloomeePlayer.loadPlaylist(
                        Playlist(tracks: state.tracks, title: 'Recently'),
                        idx: idx,
                        doPlay: true,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(6),
                            ),
                            child: SizedBox(
                              width: 52,
                              height: 52,
                              child: LoadImageCached(
                                imageUrl: track.thumbnail.urlLow ?? track.thumbnail.url,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'ReThink-Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  track.artists.map((a) => a.name).join(', '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'ReThink-Sans',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFB3B3B3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TamilHitsRow extends StatefulWidget {
  const _TamilHitsRow();

  @override
  State<_TamilHitsRow> createState() => _TamilHitsRowState();
}

class _TamilHitsRowState extends State<_TamilHitsRow> with AutomaticKeepAliveClientMixin {
  late final ContentBloc _contentBloc;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _contentBloc = ContentBloc(pluginService: ServiceLocator.pluginService);

    // Trigger the search once active plugin is resolved
    final pluginState = context.read<PluginBloc>().state;
    final resolvers = pluginState.loadedContentResolvers;
    if (resolvers.isNotEmpty) {
      final persistedId = context.read<SettingsCubit>().state.homePluginId;
      final hasPersistedPlugin = persistedId.isNotEmpty &&
          resolvers.any((p) => p.manifest.id == persistedId);
      final activeId =
          hasPersistedPlugin ? persistedId : resolvers.first.manifest.id;
      _contentBloc.add(SetActiveContentPlugin(pluginId: activeId));
      _contentBloc.add(SearchContent(
        query: 'Tamil Hits',
        filter: ContentSearchFilter.track,
      ));
    }
  }

  @override
  void dispose() {
    _contentBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<ContentBloc, ContentState>(
      bloc: _contentBloc,
      builder: (context, state) {
        final results = state.searchResults?.items ?? [];
        final tracks = results.map((item) {
          return item.maybeWhen(
            track: (t) => t,
            orElse: () => null,
          );
        }).whereType<Track>().toList();

        if (tracks.isEmpty) {
          if (state.searchStatus == SearchStatus.loading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                  color: Default_Theme.accentColor2,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tamil Hits',
                style: TextStyle(
                  fontFamily: 'Unageo',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: tracks.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return SquareImgCard(
                      imgPath: track.thumbnail.url,
                      fallbackImgPath: track.thumbnail.urlLow ?? track.thumbnail.url,
                      title: track.title,
                      subtitle: track.artists.map((a) => a.name).join(', '),
                      isList: false,
                      onTap: () {
                        context.read<BloomeePlayerCubit>().bloomeePlayer.loadPlaylist(
                          Playlist(tracks: tracks, title: 'Tamil Hits'),
                          idx: index,
                          doPlay: true,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MalayalamHitsRow extends StatefulWidget {
  const _MalayalamHitsRow();

  @override
  State<_MalayalamHitsRow> createState() => _MalayalamHitsRowState();
}

class _MalayalamHitsRowState extends State<_MalayalamHitsRow> with AutomaticKeepAliveClientMixin {
  late final ContentBloc _contentBloc;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _contentBloc = ContentBloc(pluginService: ServiceLocator.pluginService);

    // Trigger the search once active plugin is resolved
    final pluginState = context.read<PluginBloc>().state;
    final resolvers = pluginState.loadedContentResolvers;
    if (resolvers.isNotEmpty) {
      final persistedId = context.read<SettingsCubit>().state.homePluginId;
      final hasPersistedPlugin = persistedId.isNotEmpty &&
          resolvers.any((p) => p.manifest.id == persistedId);
      final activeId =
          hasPersistedPlugin ? persistedId : resolvers.first.manifest.id;
      _contentBloc.add(SetActiveContentPlugin(pluginId: activeId));
      _contentBloc.add(SearchContent(
        query: 'Malayalam Hits',
        filter: ContentSearchFilter.track,
      ));
    }
  }

  @override
  void dispose() {
    _contentBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<ContentBloc, ContentState>(
      bloc: _contentBloc,
      builder: (context, state) {
        final results = state.searchResults?.items ?? [];
        final tracks = results.map((item) {
          return item.maybeWhen(
            track: (t) => t,
            orElse: () => null,
          );
        }).whereType<Track>().toList();

        if (tracks.isEmpty) {
          if (state.searchStatus == SearchStatus.loading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                  color: Default_Theme.accentColor2,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Malayalam Hits',
                style: TextStyle(
                  fontFamily: 'Unageo',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: tracks.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return SquareImgCard(
                      imgPath: track.thumbnail.url,
                      fallbackImgPath: track.thumbnail.urlLow ?? track.thumbnail.url,
                      title: track.title,
                      subtitle: track.artists.map((a) => a.name).join(', '),
                      isList: false,
                      onTap: () {
                        context.read<BloomeePlayerCubit>().bloomeePlayer.loadPlaylist(
                          Playlist(tracks: tracks, title: 'Malayalam Hits'),
                          idx: index,
                          doPlay: true,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
