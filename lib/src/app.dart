import 'package:flutter/material.dart';

import 'features/card_reader/presentation/card_reader_page.dart';

class IcCardReaderApp extends StatelessWidget {
  const IcCardReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IC 카드 리더',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006C4C)),
        useMaterial3: true,
      ),
      home: const CardReaderPage(),
    );
  }
}
