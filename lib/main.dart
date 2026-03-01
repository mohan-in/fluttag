import 'dart:io';

import 'package:dex_compat/dex_compat.dart';
import 'package:fluttag/notifiers/audio_file_list_notifier.dart';
import 'package:fluttag/notifiers/column_settings_notifier.dart';
import 'package:fluttag/notifiers/folder_tree_notifier.dart';
import 'package:fluttag/notifiers/tag_editor_notifier.dart';
import 'package:fluttag/repositories/file_system_repository.dart';
import 'package:fluttag/repositories/id3_repository.dart';
import 'package:fluttag/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var isDesktopMode = false;
  if (Platform.isAndroid || Platform.isIOS) {
    if (Platform.isAndroid) {
      isDesktopMode = await DexCompat.isDesktopMode();
    }
  }

  runApp(FluttagApp(isDesktopMode: isDesktopMode));
}

class FluttagApp extends StatelessWidget {
  const FluttagApp({
    required this.isDesktopMode,
    super.key,
  });

  final bool isDesktopMode;

  @override
  Widget build(BuildContext context) {
    final fileSystemRepository = FileSystemRepository();
    final id3Repository = Id3Repository();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              FolderTreeNotifier(fileSystemRepository: fileSystemRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => AudioFileListNotifier(
            fileSystemRepository: fileSystemRepository,
            id3Repository: id3Repository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TagEditorNotifier(id3Repository: id3Repository),
        ),
        ChangeNotifierProvider(create: (_) => ColumnSettingsNotifier()),
      ],
      child: MaterialApp(
        title: 'fluttag',
        theme: ThemeData(
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.light,
          useMaterial3: true,
          scrollbarTheme: const ScrollbarThemeData(
            thickness: WidgetStatePropertyAll(8),
            thumbVisibility: WidgetStatePropertyAll(true),
          ),
        ),
        builder: Platform.isAndroid ? DexCompat.builder(isDesktopMode) : null,
        home: _BouncedHomeScreen(isDesktopMode: isDesktopMode),
      ),
    );
  }
}

class _BouncedHomeScreen extends StatelessWidget {
  const _BouncedHomeScreen({required this.isDesktopMode});

  final bool isDesktopMode;

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      if (!isDesktopMode) {
        final shortestSide = MediaQuery.of(context).size.shortestSide;
        // Consider screens with a shortest side < 600 as phones.
        if (shortestSide < 600) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.desktop_windows,
                      size: 64,
                      color: Colors.teal,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Large Screen Required',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Fluttag is a robust audio tag editor designed for '
                      'desktop environments.\nOn Android, please use '
                      'Samsung DeX or a large-screen tablet to access '
                      'the application.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    }
    return const HomeScreen();
  }
}
