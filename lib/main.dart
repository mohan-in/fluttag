import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fluttag/data/file_system_repository.dart';
import 'package:fluttag/data/id3_repository.dart';
import 'package:fluttag/notifiers/audio_file_list_notifier.dart';
import 'package:fluttag/notifiers/column_settings_notifier.dart';
import 'package:fluttag/notifiers/folder_tree_notifier.dart';
import 'package:fluttag/notifiers/tag_editor_notifier.dart';
import 'package:fluttag/screens/home_screen.dart';

void main() {
  runApp(const FluttagApp());
}

class FluttagApp extends StatelessWidget {
  const FluttagApp({super.key});

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
        title: 'Fluttag',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.light,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
