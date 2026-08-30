import 'dart:developer';
import 'dart:async';
import 'package:Bloomee/blocs/settings_cubit/cubit/settings_cubit.dart';
import 'package:Bloomee/core/theme/app_theme.dart';
import 'package:Bloomee/core/di/service_locator.dart';
import 'package:Bloomee/plugins/blocs/chart/chart_bloc.dart';
import 'package:Bloomee/plugins/blocs/chart/chart_event.dart';
import 'package:Bloomee/plugins/blocs/chart/chart_state.dart';
import 'package:Bloomee/plugins/blocs/plugin/plugin_bloc.dart';
import 'package:Bloomee/plugins/blocs/plugin/plugin_state.dart';
import 'package:Bloomee/screens/screen/chart/chart_view.dart';
import 'package:Bloomee/screens/screen/chart/chart_widget.dart';
import 'package:Bloomee/utils/load_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// Chart carousel widget that displays charts from loaded chart provider plugins.
class CaraouselWidget extends StatefulWidget {
  const CaraouselWidget({super.key});

  @override
  State<CaraouselWidget> createState() => _CaraouselWidgetState();
}

class _CaraouselWidgetState extends State<CaraouselWidget> with AutomaticKeepAliveClientMixin {
  late final ChartBloc _chartBloc;
  ValueNotifier<bool> autoSlideCharts = ValueNotifier(true);
  StreamSubscription<SettingsState>? _settingsSub;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _chartBloc = ChartBloc(pluginService: ServiceLocator.pluginService);
    autoSlideCharts.value = context.read<SettingsCubit>().state.autoSlideCharts;
    _settingsSub = context.read<SettingsCubit>().stream.listen((event) {
      if (autoSlideCharts.value != event.autoSlideCharts) {
        autoSlideCharts.value = event.autoSlideCharts;
      }
    });
    _loadChartsFromPlugin();
  }

  void _loadChartsFromPlugin() {
    final chartProviders =
        context.read<PluginBloc>().state.loadedChartProviders;
    if (chartProviders.isNotEmpty) {
      final pluginId = chartProviders.first.manifest.id;
      log('Loading charts from plugin: $pluginId', name: 'ChartCarousel');
      _chartBloc.add(LoadCharts(pluginId: pluginId));
    } else {
      log('No chart provider plugins loaded — charts unavailable',
          name: 'ChartCarousel');
    }
  }

  @override
  void dispose() {
    _settingsSub?.cancel();
    _chartBloc.close();
    autoSlideCharts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<ChartBloc, ChartState>(
      bloc: _chartBloc,
      listenWhen: (previous, current) =>
          previous.chartsStatus != ChartStatus.loaded &&
          current.chartsStatus == ChartStatus.loaded,
      listener: (context, chartState) {
        final pluginId = chartState.activePluginId;
        if (pluginId == null || chartState.charts.isEmpty) return;
        final settingsState = context.read<SettingsCubit>().state;
        final visibleIds = chartState.charts
            .where((c) => settingsState.chartMap[c.title] ?? true)
            .map((c) => c.id)
            .toSet();
        if (visibleIds.isNotEmpty) {
          _chartBloc.add(PrefetchAllChartDetails(
            pluginId: pluginId,
            chartIds: visibleIds,
          ));
        }
      },
      child: BlocBuilder<PluginBloc, PluginState>(
        builder: (context, pluginState) {
          if (pluginState.loadedChartProviders.isEmpty) {
            _chartBloc.add(const ClearCharts());
          } else if (_chartBloc.state.chartsStatus == ChartStatus.initial) {
            _loadChartsFromPlugin();
          }
          return BlocBuilder<ChartBloc, ChartState>(
            bloc: _chartBloc,
            builder: (context, chartState) {
              if (chartState.charts.isEmpty) return const SizedBox.shrink();

              final settingsState = context.watch<SettingsCubit>().state;
              final visibleCharts = chartState.charts
                  .where((c) => settingsState.chartMap[c.title] ?? true)
                  .toList();

              if (visibleCharts.isEmpty) return const SizedBox.shrink();

              if (isAndroidPlatform) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Featured Charts',
                        style: TextStyle(
                          fontFamily: 'Unageo',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 180,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: visibleCharts.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            final chart = visibleCharts[index];
                            final artwork = chart.thumbnail;
                            final thumbnailUrl = artwork?.urlHigh ??
                                artwork?.url ??
                                artwork?.urlLow ??
                                '';
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChartScreen(
                                      pluginId:
                                          _chartBloc.state.activePluginId ?? '',
                                      chartId: chart.id,
                                      chartTitle: chart.title,
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 130,
                                  height: 180,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      LoadImageCached(
                                        imageUrl: thumbnailUrl,
                                        fit: BoxFit.cover,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withValues(alpha: 0.3),
                                              Colors.black.withValues(alpha: 0.85),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 10,
                                        right: 10,
                                        bottom: 10,
                                        child: Text(
                                          chart.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.2,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ValueListenableBuilder<bool>(
                  valueListenable: autoSlideCharts,
                  builder: (context, autoPlay, child) {
                    return CarouselSlider.builder(
                      itemCount: visibleCharts.length,
                      itemBuilder: (context, index, realIndex) {
                        final chart = visibleCharts[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChartScreen(
                                  pluginId:
                                      _chartBloc.state.activePluginId ?? '',
                                  chartId: chart.id,
                                  chartTitle: chart.title,
                                ),
                              ),
                            );
                          },
                          child: ChartWidget(
                            chart: chart,
                            pluginId: _chartBloc.state.activePluginId ?? '',
                          ),
                        );
                      },
                      options: CarouselOptions(
                        height: ResponsiveBreakpoints.of(context).isMobile ||
                                ResponsiveBreakpoints.of(context).isTablet
                            ? MediaQuery.of(context).size.height * 0.36
                            : 250,
                        viewportFraction:
                            ResponsiveBreakpoints.of(context).isMobile
                                ? 0.65
                                : ResponsiveBreakpoints.of(context).isTablet
                                    ? 0.40
                                    : 0.30,
                        autoPlay: isAndroidPlatform ? false : autoPlay,
                        autoPlayInterval: const Duration(milliseconds: 2500),
                        enlargeFactor: 0.2,
                        initialPage: 0,
                        pauseAutoPlayOnTouch: true,
                        padEnds: true,
                        enlargeCenterPage:
                            ResponsiveBreakpoints.of(context).isMobile,
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
