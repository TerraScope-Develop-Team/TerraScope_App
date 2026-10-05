import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:terrascope/main.dart';
import 'package:terrascope/providers/retos_observer_provider.dart';
import 'package:terrascope/services/notification_service.dart';
import 'package:terrascope/services/theme_service.dart';

void main() {
  testWidgets('TerraScope app starts with its required providers', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => RetosObserverProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => NotificationService()),
        ],
        child: const MyApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
