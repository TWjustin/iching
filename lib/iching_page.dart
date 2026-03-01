// ignore_for_file: library_private_types_in_public_api

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'iching_data.dart';

// 1. 定義爻的資料結構
enum IchingLine {
  oldYin(6, "⚋", "x"),    
  youngYang(7, "⚊", ""),   
  youngYin(8, "⚋", ""),    
  oldYang(9, "⚊", "o");   

  final int score;
  final String symbol; 
  final String mark;   
  const IchingLine(this.score, this.symbol, this.mark);
}

class IchingPage extends StatefulWidget {
  const IchingPage({super.key}); // 加入 key 可以讓編譯器更開心
  @override
  _IchingPageState createState() => _IchingPageState();
}

class _IchingPageState extends State<IchingPage> {
  // 核心數據：儲存目前的爻
  List<IchingLine?> lines = List.filled(6, null); // 建立一個長度為 6 且初始為空的列表
  int _currentStep = 0; // 用來追蹤目前投到第幾爻
  List<int> _currentCoins = []; // 儲存這一次的三個硬幣，例如 [2, 3, 2]
  
  // 2. 投擲邏輯 (腳本核心)
  void _generateNextLine() {
    if (_currentStep >= 6) return;

    final random = Random();
    int c1 = random.nextBool() ? 3 : 2;
    int c2 = random.nextBool() ? 3 : 2;
    int c3 = random.nextBool() ? 3 : 2;
    int totalScore = c1 + c2 + c3;

    setState(() {
      // 1. 更新硬幣顯示數據 (解決硬幣不出現的問題)
      _currentCoins = [c1, c2, c3]; 
      
      // 2. 更新爻象數據
      lines[_currentStep] = IchingLine.values.firstWhere((e) => e.score == totalScore);
      _currentStep++;
    });
    
    HapticFeedback.mediumImpact();
  }

  void _resetDivination() {
    setState(() {
      lines = List.filled(6, null); // 重新填滿 null
      _currentStep = 0;
      _currentCoins.clear();
    });
    HapticFeedback.lightImpact();
  }

  // 1. 取得 X之X 的卦名對 (例如：乾之坤)
  String _getHexagramNamePair() {
    final activeLines = lines.whereType<IchingLine>().toList();
    if (activeLines.length < 6) return ""; // 安全檢查

    // 計算本卦與變卦卦碼
    String originalCode = activeLines.map((line) => (line.score == 7 || line.score == 9) ? "1" : "0").join();
    String changedCode = activeLines.map((line) {
      bool isYang = (line.score == 7 || line.score == 9);
      bool isMoving = (line.score == 6 || line.score == 9);
      if (isMoving) return isYang ? "0" : "1"; // 變爻
      return isYang ? "1" : "0";
    }).join();

    // 取得資料
    var original = ichingData[originalCode] ?? {"name": "未知"};
    var changed = ichingData[changedCode] ?? {"name": "未知"};

    // 如果無變爻，只顯示本卦名
    if (originalCode == changedCode) {
      return original['name']!;
    } else {
      // 顯示 X之X
      return "${original['abbr']!}之${changed['abbr']!}";
    }
  }

  // 2. 取得變爻的國字名稱 (例如：初、二)
  String _getMovingLineNames() {
    final activeLines = lines.whereType<IchingLine>().toList();
    if (activeLines.length < 6) return ""; // 安全檢查

    // 找出所有變爻 (oldYin 或 oldYang)
    List<String> movingNames = [];
    for (int i = 0; i < activeLines.length; i++) {
      var line = activeLines[i];
      if (line.score == 6 || line.score == 9) {
        // 取得國字序 (初、二、三...)
        movingNames.add(getLineName(i + 1)); 
      }
    }

    // 將變爻名稱連接起來，並用括號包住 (選用，讓視覺更真誠)
    if (movingNames.isEmpty) return "";
    return movingNames.join('、');
  }

  // 在 _IchingPageState 類別內加入
  void _showResult() {
    // 1. 過濾掉 null 並確保只取前 6 爻（防止非預期錯誤）
    // 因為 lines 現在是 [line, line, null, null, null, null] 這種形式
    final activeLines = lines.whereType<IchingLine>().toList();

    if (activeLines.length < 6) return; // 安全檢查

    // 2. 計算本卦卦碼
    String originalCode = activeLines.map((line) {
      return (line.score == 7 || line.score == 9) ? "1" : "0";
    }).join();
    
    // 3. 計算變卦卦碼
    String changedCode = activeLines.map((line) {
      bool isYang = (line.score == 7 || line.score == 9);
      bool isMoving = (line.score == 6 || line.score == 9);
      
      if (isMoving) {
        return isYang ? "0" : "1"; // 變爻：陽變陰，陰變陽
      } else {
        return isYang ? "1" : "0"; // 不變
      }
    }).join();

    // 4. 取得資料並顯示 (其餘邏輯不變)
    var original = ichingData[originalCode] ?? {"name": "未知", "meaning": ""};
    var changed = ichingData[changedCode] ?? {"name": "未知", "meaning": ""};

    // 4. 彈出 iOS 風格的對話框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF262626), // 深色彈窗背景
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Center(
          child: Text("占卜結果", style: TextStyle(color: Color(0xFFF2EFE9), fontWeight: FontWeight.bold))
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("本卦", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            Text(original['name']!, style: const TextStyle(fontSize: 24, color: Color(0xFFF2EFE9), fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(original['meaning']!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFCCCCCC))),

            if (originalCode != changedCode) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Divider(color: Colors.white10, thickness: 1),
              ),
              const Text("變卦", style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              Text(changed['name']!, style: const TextStyle(fontSize: 20, color: Color(0xFFF2EFE9), fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(changed['meaning']!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFCCCCCC))),
            ],
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("了解", style: TextStyle(color: Color(0xFFF2EFE9))),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // 深炭灰色背景
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // 1. 固定頂部邊距：確保卦象不會貼著螢幕頂端
              SizedBox(height: screenHeight * 0.08),

              // 2. 文字顯示區：給予固定高度 (100)，不管內容有沒有出現都佔著空間
              Align(
                alignment: Alignment.center, 
                child: SizedBox(
                  height: 100, 
                  child: _currentStep == 6
                      ? Column(
                          mainAxisSize: MainAxisSize.min, 
                          mainAxisAlignment: MainAxisAlignment.center, // 垂直居中
                          children: [
                            // 第一行：卦名 (例如：乾、乾之坤)
                            Text(
                              _getHexagramNamePair(),
                              style: const TextStyle(
                                color: Color(0xFFF2EFE9),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // 第二行：動幾爻 + 複製按鈕
                            Row(
                              mainAxisSize: MainAxisSize.min, // 讓 Row 寬度剛好包覆內容
                              children: [
                                Text(
                                  // 判斷是否有變爻，若無則顯示「無動爻」
                                  _getMovingLineNames().isNotEmpty 
                                      ? "動${_getMovingLineNames()}爻" 
                                      : "無動爻",
                                  style: const TextStyle(
                                    color: Color(0xFF888888),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 12), // 文字與按鈕的間距
                                GestureDetector(
                                  onTap: () {
                                    // 複製內容同步調整：若無動爻則複製「卦名 無動爻」
                                    final movingInfo = _getMovingLineNames().isNotEmpty 
                                        ? "動${_getMovingLineNames()}爻" 
                                        : "無動爻";
                                    // 組合複製文字：例如 "剝之益 動初、五爻"
                                    final copyText = "${_getHexagramNamePair()} $movingInfo";
                                    
                                    Clipboard.setData(ClipboardData(text: copyText));
                                    // 輕微觸覺回饋，增加質感
                                    HapticFeedback.mediumImpact();

                                    // 顯示短暫提示
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text("占卜結果已複製", textAlign: TextAlign.center),
                                        backgroundColor: const Color(0xFF333333),
                                        behavior: SnackBarBehavior.floating,
                                        width: 200,
                                        duration: const Duration(milliseconds: 800),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    );
                                  },
                                  child: const Icon(
                                    Icons.copy_all_rounded,
                                    color: Color(0xFF555555), // 比文字更暗一點，不搶戲
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),

              // 如果占卜中，可以顯示一個淡淡的佔位空間，保持重心穩定
              // if (_currentStep < 6)
              //   const SizedBox(height: 70), // 預留兩行文字的高度

              const SizedBox(height: 20), // 文字區與卦象的間距

              // 爻象區：固定顯示 6 個位置
              Column(
                children: List.generate(6, (index) {
                  // 由上往下排，但邏輯上 index 5 是最上面的「上爻」
                  int reversedIndex = 5 - index; 
                  var lineData = lines[reversedIndex];

                  return Opacity(
                    // 如果該位置還沒投出來，透明度設為 0 (隱藏但佔位)
                    opacity: lineData == null ? 0.0 : 1.0, 
                    child: _buildLine(lineData ?? IchingLine.youngYang, reversedIndex + 1),
                  );
                }),
              ),

              const SizedBox(height: 10),
              _buildCoinDisplay(),
              
              
              // 按鈕區
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _currentStep < 6
                    ? _buildNextButton()  // 階段一：占卜中 (下一爻)
                    : _buildResultButtons(),  // 階段二：占卜完成 (查看結果 與 再來一次)
              ),
            ],
          ),
        ),
      )
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: _generateNextLine,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF2EFE9), // 象牙色
        foregroundColor: const Color(0xFF1A1A1A), // 深炭灰文字
        minimumSize: const Size(200, 50), // 寬度 200, 高度固定 50
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
      ),
      child: const Text(
        '下一爻', 
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)
      ),
    );
  }

  Widget _buildResultButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _showResult,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF2EFE9), // 象牙色
            foregroundColor: const Color(0xFF1A1A1A),
            minimumSize: const Size(120, 50), // 高度固定 50
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('查看結果', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: _resetDivination,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF333333), // 深灰色
            foregroundColor: const Color(0xFFF2EFE9),
            minimumSize: const Size(120, 50), // 高度固定 50
            side: const BorderSide(color: Color(0xFF444444)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('再來一次'),
        ),
      ],
    );
  }

  Widget _buildCoinDisplay() {
  // 即使沒有硬幣，也回傳一個固定高度的 Container
    return Container(
      height: 110, // 硬幣上下高度
      alignment: Alignment.center,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF2EFE9).withValues(alpha: 0.04), // 象牙色淡光
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: _currentCoins.isEmpty
          ? Text("點擊下方開始占卜", style: TextStyle(color: Colors.grey[400], letterSpacing: 1.5))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _currentCoins.map((score) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 60,
                  height: 60,
                  child: Image.asset(
                    // 根據分數判斷顯示哪張圖
                    score == 3 ? 'assets/coin_heads.png' : 'assets/coin_tails.png',
                    fit: BoxFit.contain,
                  ),
                );
              }).toList(),
            ),
    );
  }

  // 繪製陰陽爻的質感圖形
  Widget _buildLine(IchingLine? line, int index) {
    // 基礎判斷
    bool hasData = line != null;
    bool isYang = hasData && (line.score == 7 || line.score == 9);
    bool isMoving = hasData && (line.score == 6 || line.score == 9);

    const Color lineColor = Color(0xFFF2EFE9); // 象牙色
    const Color placeholderColor = Color(0xFF2A2A2A); // 佔位條顏色
    const double lineHeight = 22.0;
    const double fullWidth = 190.0;
    const double gapWidth = 30.0;
    const double segmentWidth = (fullWidth - gapWidth) / 2;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // --- 左側：爻序 ---
          Container(
            width: 50,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 15),
            child: Text(
              getLineName(index),
              style: const TextStyle(color: Color(0xFF555555), fontSize: 14),
            ),
          ),

          // --- 中間：爻象本體 ---
          SizedBox(
            width: fullWidth,
            height: lineHeight,
            child: Stack(
              children: [
                // 1. 底層佔位：當 hasData 時寬度變 0，顏色漸變
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  width: hasData ? 0 : fullWidth, // 寬度動畫
                  height: lineHeight,
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: hasData ? lineColor : placeholderColor,
                  ),
                ),

                // 2. 上層爻象：使用 AnimatedOpacity + ScaleTransition 包裹
                // 重點：移除內部的 if (hasData) 條件渲染，改用透明度和縮放動畫控制
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: hasData ? 1.0 : 0.0,
                  curve: Curves.easeOutBack,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.7, end: hasData ? 1.0 : 0.7),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: isYang 
                      ? Container( // 陽爻：整條長方形
                          width: fullWidth,
                          height: lineHeight,
                          decoration: BoxDecoration(
                            color: lineColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                        )
                      : Row( // 陰爻：兩段式
                          children: [
                            Container(width: segmentWidth, height: lineHeight, color: lineColor),
                            SizedBox(width: gapWidth),
                            Container(width: segmentWidth, height: lineHeight, color: lineColor),
                          ],
                        ),
                  ),
                ),
              ],
            ),
          ),

          // --- 右側：OX 標記 ---
          Container(
            width: 50,
            padding: const EdgeInsets.only(left: 10),
            alignment: Alignment.centerLeft,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              opacity: isMoving ? 1.0 : 0.0,
              curve: Curves.easeOutBack, // 讓符號跳出來的感覺更明顯
              child: Icon(
                hasData && line.score == 9 ? Icons.circle_outlined : Icons.close,
                color: Colors.redAccent.withValues(alpha: 0.8), // 紅色標記，帶點透明感
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 定義國字爻序
  String getLineName(int index) {
    switch (index) {
      case 1: return "初";
      case 2: return "二";
      case 3: return "三";
      case 4: return "四";
      case 5: return "五";
      case 6: return "上";
      default: return "";
    }
  }
}