import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/layout/responsive_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: SpotiCloneApp(),
    ),
  );
}

class SpotiCloneApp extends StatelessWidget {
  const SpotiCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpotiClone',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const ResponsiveShell(),
    );
  }
}
