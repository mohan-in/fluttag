# Fluttag Architecture

This document describes the high-level architecture of Fluttag, a desktop ID3 tag editor built with Flutter.

## Core Principles

-   **Separation of Concerns**: The application strictly separates the UI (Widgets), State (Notifiers), and Data abstraction (Repositories/Models).
-   **Dependency Injection**: Dependencies are injected at the root of the widget tree using `Provider` (`MultiProvider`).
-   **No UI State Bleed**: The UI (`Widgets`) is purely declarative and reacts to state changes via `ChangeNotifier`. Widgets do not hold complex, mutable business logic.
-   **Strict Typing**: Dynamic types are avoided. All models and functions are strongly typed.

## Directory Structure
The `lib/` directory is organized into the following major components:

```
lib/
├── main.dart                 # Application entry point, DI setup, and Theme
├── models/                   # Domain entities and value objects
│   ├── audio_file.dart       # Represents a parsed audio track with ID3 metadata
│   └── folder_node.dart      # Represents a directory node in the folder tree
├── repositories/             # Data access and external API abstraction
│   ├── file_system_repository.dart  # Handles file parsing and directory iteration
│   └── id3_repository.dart   # Abstracts reading/writing ID3 tags via 'audiotags'
├── notifiers/                # Business logic and UI state controllers (ChangeNotifiers)
│   ├── audio_file_list_notifier.dart # Manages the loaded list of files, sorting, and multi-selection state
│   ├── column_settings_notifier.dart  # Manages dynamic column widths and visibility
│   ├── folder_tree_notifier.dart      # Manages the currently selected directory and tree expansion
│   └── tag_editor_notifier.dart       # Manages the metadata editing fields and coordinates batch saving
├── screens/                  # Top-level screen layouts
│   ├── home_screen.dart      # The main split-pane layout scaffold
│   └── editor_screen.dart    # A wrapper screen combining the file list and tag editor
└── widgets/                  # Reusable UI components
    ├── audio_file_list_pane.dart # The robust DataTable displaying files
    ├── folder_tree_pane.dart     # The recursive folder navigation tree
    └── tag_editor_pane.dart      # The metadata entry form and save buttons
```

## State Management Flow

1.  **Repositories** (`lib/repositories/`) are instantiated once in `main.dart` and injected into specific Notifiers.
2.  **Notifiers** (`lib/notifiers/`) extend `ChangeNotifier`. They hold the application's single source of truth for their respective domain (e.g., the `AudioFileListNotifier` holds the list of `AudioFile` objects and the current `Set` of selected files).
3.  **Widgets** (`lib/widgets/`) use `context.watch<T>()`, `context.select<T, R>()`, or `Consumer<T>` to rebuild when Notifiers call `notifyListeners()`.
4.  **User Actions** (e.g., clicking a column header to sort) call methods directly on the Notifiers via `context.read<T>()`. The Notifier performs the logic (e.g., sorting the internal list) and calls `notifyListeners()`, causing the UI to update.

## Batch Editing Architecture

A key feature of Fluttag is its ability to edit multiple files simultaneously.

1.  When a user selects multiple files in the `AudioFileListPane`, the `AudioFileListNotifier` updates its `selectedFiles` property.
2.  The `TagEditorPane` reacts to changes in `selectedFiles`. If multiple files are selected, it determines the "common denominator" for fields like Artist or Album. If all selected files share the same artist, that artist is displayed. If they differ, the field is left blank. "Per-file" fields like Title and Track Number are intentionally disabled during multi-selection.
3.  When the user edits a field (e.g., changes the Genre dropdown) and clicks "Save All", the `TagEditorNotifier` clones each selected `AudioFile` object, applies only the modified fields, and delegates the disk save operation to the `Id3Repository`.

## Theming
Fluttag utilizes Material Design 3. Instead of hardcoding colors, the application relies on `Theme.of(context).colorScheme` (seeded with `Colors.teal`) to ensure maximum consistency and future-proofing against dark mode or platform-specific theme adaptations.
