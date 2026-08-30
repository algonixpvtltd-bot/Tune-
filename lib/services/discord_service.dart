import 'dart:developer';
import 'dart:io';
import 'package:Bloomee/core/models/exported.dart';
import 'package:Bloomee/core/constants/sentinel_values.dart';

// Discord RPC package removed - incompatible with modern Dart SDK.
// This is a no-op stub for Android builds. Desktop builds can re-enable
// by adding dart_discord_rpc back once a compatible version is published.

class DiscordService {
  static void initialize() {
    log("Discord RPC disabled (package removed for SDK compatibility)", name: "DiscordService");
  }

  static void updatePresence({
    required Track track,
    required bool isPlaying,
  }) {}

  static void clearPresence() {}
}
