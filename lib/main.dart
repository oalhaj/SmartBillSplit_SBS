import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/screens/assign_screen.dart';
import 'ui/screens/capture_screen.dart';
import 'ui/screens/charges_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/participants_screen.dart';
import 'ui/screens/review_edit_screen.dart';
import 'ui/screens/summary_screen.dart';

void main() {
  runApp(const ProviderScope(child: SplitSnapApp()));
}

class SplitSnapApp extends StatelessWidget {
  const SplitSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SplitSnap',
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      initialRoute: HomeScreen.routeName,
      routes: {
        HomeScreen.routeName: (context) => const HomeScreen(),
        CaptureScreen.routeName: (context) => const CaptureScreen(),
        ReviewEditScreen.routeName: (context) => const ReviewEditScreen(),
        ParticipantsScreen.routeName: (context) => const ParticipantsScreen(),
        AssignScreen.routeName: (context) => const AssignScreen(),
        ChargesScreen.routeName: (context) => const ChargesScreen(),
        SummaryScreen.routeName: (context) => const SummaryScreen(),
      },
    );
  }
}
