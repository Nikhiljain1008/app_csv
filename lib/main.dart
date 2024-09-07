import 'package:app_csv/chartdisplaypage.dart';
import 'package:app_csv/columnselectionpage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data_provider.dart';
import 'generalinfo.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => DataProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      initialRoute: '/average',
      routes: {
        '/average': (context) => const AverageCalculationPage(),
        '/charts': (context) => SelectionPage(),
        '/chartPage': (context) => ChartPage(),
      },
    );
  }
}
