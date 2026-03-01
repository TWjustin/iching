import 'package:flutter/material.dart';
import 'iching_page.dart'; // 確保你的 iching_page.dart 檔案在同一個目錄下

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 移除右上角的 Debug 標籤，讓畫面更乾淨
      title: '易經占卜',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.brown, // 易經可以用比較沉穩的木質色系
      ),
      // 直接將 home 指向你的占卜頁面
      home: const IchingPage(), 
    );
  }
}