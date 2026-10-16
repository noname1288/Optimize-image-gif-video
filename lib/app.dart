import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/main/presentation/pages/main_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Preload Img Vid',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    home: const MainPage(),
  );
}
