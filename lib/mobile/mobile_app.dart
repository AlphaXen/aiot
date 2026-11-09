import 'package:flutter/material.dart';

import 'mobile_theme.dart';
import 'screens/home_shell.dart';

/// 캠퍼스 식당 혼잡도 · AI 추천 웹앱.
/// 데스크톱 브라우저에서 열어도 폰 너비(최대 480px)로 가운데 정렬됩니다.
class MobileApp extends StatelessWidget {
  const MobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '캠퍼스 식당',
      debugShowCheckedModeBanner: false,
      theme: buildMobileTheme(Brightness.light),
      darkTheme: buildMobileTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return ColoredBox(
          color: dark ? const Color(0xFF111111) : const Color(0xFFE4E4EA),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ClipRect(child: child),
            ),
          ),
        );
      },
      home: const HomeShell(),
    );
  }
}
