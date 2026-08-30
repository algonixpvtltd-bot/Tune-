// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:Bloomee/blocs/media_player/bloomee_player_cubit.dart';
import 'package:Bloomee/utils/load_image.dart';
import 'package:flutter/material.dart';
import 'package:Bloomee/core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';
import 'package:Bloomee/core/icons/app_icons.dart';

enum LibItemTypes {
  userPlaylist,
  onlPlaylist,
  artist,
  album,
}

class LibItemCard extends StatelessWidget {
  final String title;
  final String coverArt;
  final String subtitle;
  final LibItemTypes type;
  final VoidCallback? onTap;
  final VoidCallback? onSecondaryTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMenuTap;
  final bool showMenuButton;
  final bool isPinned;
  const LibItemCard({
    Key? key,
    required this.title,
    required this.coverArt,
    required this.subtitle,
    this.type = LibItemTypes.userPlaylist,
    this.onTap,
    this.onSecondaryTap,
    this.onLongPress,
    this.onMenuTap,
    this.showMenuButton = false,
    this.isPinned = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8),
      child: InkWell(
        splashColor: Default_Theme.primaryColor2.withValues(alpha: 0.1),
        hoverColor: Colors.white.withValues(alpha: 0.05),
        highlightColor: Default_Theme.primaryColor2.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        onTap: onTap ?? () {},
        onSecondaryTap: onSecondaryTap ?? () {},
        onLongPress: onLongPress ?? () {},
        child: SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              type == LibItemTypes.userPlaylist
                  ? StreamBuilder<String>(
                      stream: context
                          .watch<BloomeePlayerCubit>()
                          .bloomeePlayer
                          .queueTitle,
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data == title) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              AppIcons.chartSimpleSolid,
                              color: Default_Theme.primaryColor2
                                  .withValues(alpha: 1),
                              size: 15,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      })
                  : const SizedBox.shrink(),
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: SizedBox.square(
                  dimension: 70,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: switch (type) {
                      LibItemTypes.userPlaylist => LoadImageCached(
                          imageUrl: coverArt,
                          fallbackUrl: coverArt.toString(),
                          customPlaceholder: Container(
                            color: const Color(0xFF1E1E1E),
                            alignment: Alignment.center,
                            child: Icon(
                              MingCuteIcons.mgc_playlist_fill,
                              color: Colors.white.withValues(alpha: 0.35),
                              size: 28,
                            ),
                          ),
                        ),
                      LibItemTypes.onlPlaylist => LoadImageCached(
                          imageUrl: coverArt,
                          fallbackUrl: coverArt.toString(),
                          customPlaceholder: Container(
                            color: const Color(0xFF1E1E1E),
                            alignment: Alignment.center,
                            child: Icon(
                              MingCuteIcons.mgc_playlist_fill,
                              color: Colors.white.withValues(alpha: 0.35),
                              size: 28,
                            ),
                          ),
                        ),
                      LibItemTypes.artist => ClipOval(
                          child: LoadImageCached(
                            imageUrl: coverArt,
                            fallbackUrl: coverArt.toString(),
                            customPlaceholder: Container(
                              color: const Color(0xFF1E1E1E),
                              alignment: Alignment.center,
                              child: Icon(
                                MingCuteIcons.mgc_user_3_line,
                                color: Colors.white.withValues(alpha: 0.35),
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      LibItemTypes.album => LoadImageCached(
                          imageUrl: coverArt,
                          fallbackUrl: coverArt.toString(),
                          customPlaceholder: Container(
                            color: const Color(0xFF1E1E1E),
                            alignment: Alignment.center,
                            child: Icon(
                              MingCuteIcons.mgc_disc_line,
                              color: Colors.white.withValues(alpha: 0.35),
                              size: 28,
                            ),
                          ),
                        ),
                    },
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: Default_Theme.secondoryTextStyle.merge(
                          const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: Default_Theme.primaryColor1)),
                    ),
                    Row(
                      children: [
                        if (isPinned) ...[
                          Icon(
                            MingCuteIcons.mgc_pin_2_fill,
                            size: 12,
                            color: Default_Theme.accentColor2
                                .withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            style: Default_Theme.secondoryTextStyle.merge(
                                const TextStyle(
                                    fontSize: 14,
                                    overflow: TextOverflow.fade,
                                    fontWeight: FontWeight.w500,
                                    color: Default_Theme.primaryColor1)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (showMenuButton)
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: IconButton(
                    onPressed: onMenuTap,
                    splashRadius: 20,
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color:
                          Default_Theme.primaryColor1.withValues(alpha: 0.72),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
