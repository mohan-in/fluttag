# Fluttag

A sleek, intuitive desktop application for Linux built with Flutter, designed to help you easily view and batch-edit ID3 tags for your audio files.

![Fluttag](assets/app_icon.png)

## Features

- **Split-Pane Interface**: Easily navigate your local file system, view your audio files in a comprehensive list, and edit tags in a dedicated side pane.
- **Batch Editing**: Select multiple audio files at once to quickly apply common tags (such as Artist, Album, Year, Genre, and Album Art) everywhere simultaneously.
- **Robust Tagging**: Read and write ID3 metadata seamlessly using the `audiotags` package. Supports altering:
  - Title
  - Artist
  - Album
  - Year
  - Genre
  - Track
  - Comment
  - Album Cover Art (read/write picture bytes)
- **Advanced File List**: Sort audio files by various property columns (Name, Track, Year, File Size, etc.) and easily resize columns.
- **Modern Material 3 Design**: Clean typography, proper state indicators, and native system theming.

## Getting Started

To run the application locally on Linux:

1. Ensure you have the Flutter SDK installed and your Linux desktop environment configured.
2. Clone this repository and navigate to its root directory.
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run -d linux
   ```

## Build for Release

To build a release bundle for Linux:
```bash
flutter build linux
```
The compiled executable and assets will be placed inside `build/linux/x64/release/bundle/`.
