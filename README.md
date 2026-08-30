# 🎵 Tune

**A unified local and plugin-first streaming music player built with Flutter & Rust.**

**Tune** is an open-source music player designed to give you absolute freedom over your audio. Seamlessly mix your **local device music** with an infinite universe of streams powered by a secure, **Rust-backed plugin system**. No ads, no interruptions—just your tunes, your way. 🎵

---

## 🚀 Features

- 🚫 **Ad-Free Experience:** Zero interruptions, just pure music.
- 🦀 **Plugins system:** Secure, auto-updating `.bex` plugin system for endless music sources.
- 📂 **Local Music:** Play your local offline music seamlessly alongside online streams.
- 🎤 **Karaoke-Style Lyrics:** Time-synced lyrics with manual offset adjustment.
- 🎛️ **Audio Equalizer:** Built-in Equalizer and customizable Crossfade transitions.
- 🔄 **Smart Replace:** Auto-recovery finds working streams if a playlist track goes dead.
- 📊 **Last.fm Scrobbling:** Automatically log your listening history (includes offline caching).
- 🎮 **Discord Rich Presence:** Show off your current tunes on your Discord profile.
- 🌍 **Global Charts:** Daily updated charts from installed plugins.
- 🖥️ **Cross-Platform:** Native media controls and shortcuts for Windows, Linux, and Android.
- 💾 **Backup & Restore:** Easily export/import your library and settings via JSON or M3U.
- 🤖 **AI-Based Recommendations:** Get smarter song suggestions (Last.fm/Plugin Based).
- 🆎 **Multi-Language Support:** Localized app interface for global users.

---

## 🛠️ Architecture

The app is split into two core layers:
1. **Frontend (Flutter):** Provides a modern, responsive, and beautiful user interface built with the BLoC state management pattern.
2. **Backend (Rust):** A highly performant, memory-safe, and sandboxed native layer responsible for managing plugins, database operations, and audio processing pipelines.

---

## 🚀 Getting Started

### Prerequisites

To build the project from source, you will need:
- **Flutter SDK** (Latest stable version)
- **Rust Toolchain** (Latest stable version)
- **flutter_rust_bridge_codegen**

### Installation & Run

1. Clone the repository:
   ```bash
   git clone https://github.com/algonixpvtltd-bot/Tune-.git
   cd Tune-
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

---

## 🤝 Contributing

Contributions are always welcome! Feel free to open issues or submit pull requests to help improve the project.

---

## 📄 License

This project is licensed under the GPL-3.0 License.