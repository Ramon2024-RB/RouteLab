import 'package:flutter/material.dart';

import '../features/home/home_page.dart';

class RouteLabApp extends StatelessWidget {
  const RouteLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF39F47B);
    return MaterialApp(
      title: 'RouteLab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF09140F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF09140F)),
      ),
      home: const RouteLabHome(),
    );
  }
}
