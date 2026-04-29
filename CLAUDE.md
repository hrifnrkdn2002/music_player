# CLAUDE.md

Instructions for Claude when working in this project.

## Project Overview

A Flutter music player app targeting Android/iOS. Supports local music file playback, playlists, download, and theming.

## Tech Stack

- **Framework**: Flutter (Dart, SDK ^3.11.1)
- **State management**: Provider (`provider: ^6.1.2`)
- **Audio playback**: `just_audio: ^0.9.36`
- **Database**: SQLite via `sqflite: ^2.4.2`
- **File picking**: `file_picker: ^10.3.2`

## Project Structure

```
lib/
  main.dart                        # App entry point
  DB/
    DatabaseHelper.dart            # SQLite CRUD operations
    DB_Provider.dart               # DB access abstraction
  Model/
    Song.dart                      # Song data model
  Provider/
    MusicProvider.dart             # Playback state & logic
    ThemeProvider.dart             # Theme state
  UI/
    HomePage.dart                  # Main screen
    PlayerPage.dart                # Full-screen player
    mini_player.dart               # Mini player widget
    PlaylistPage.dart              # Playlist list screen
    PlaylistDetailPage.dart        # Songs in a playlist
    AddSongToPlaylistPage.dart     # Add songs to playlist
    DownloadPage.dart              # Download screen
    SettingsPage.dart              # App settings
  Utils/
    AppTheme.dart                  # Theme definitions
    DurationFormatter.dart         # Duration formatting helpers
```

## Coding Conventions

- Use `Provider` for state — do not use `setState` for shared state.
- Keep UI logic in Provider classes, not in widget files.
- All DB operations go through `DatabaseHelper`; do not call `sqflite` directly from UI or Provider.
- Use `DurationFormatter` for any duration-to-string formatting.
- File names and class names use PascalCase for classes, camelCase for variables/functions.

## Common Commands

```bash
# Run the app
flutter run

# Analyze code
flutter analyze

# Run tests
flutter test

# Get dependencies
flutter pub get
```

## Notes

- The app currently targets Android primarily; iOS support is secondary.
- Background audio and notification mini-player are planned but not yet implemented.
- Playlist feature is partially implemented (see commit history).
