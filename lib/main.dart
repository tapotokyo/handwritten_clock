import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:flutter/services.dart'; // ステータスバー操作用

// main関数を書き換え
void main() {
  // アプリの準備ができるまで待つおまじない
  WidgetsFlutterBinding.ensureInitialized();

  // ★ステータスバーとナビゲーションバーを隠す（没入モード）
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ClockScreen(),
  ));
}

// ==========================================
// 1. 時計画面（全画面・タップでUI表示版）
// ==========================================
class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});
  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  String? _docsDir;
  DateTime _now = DateTime.now();

  // 設定変数
  bool _showSeconds = true;
  bool _is24Hour = true;
  Color _bgColor = Colors.black;
  Color _numColor = Colors.white;
  String _language =
      Lang.codes.contains(PlatformDispatcher.instance.locale.languageCode)
          ? PlatformDispatcher.instance.locale.languageCode
          : 'en';

  // ★追加：ボタン類を表示しているかどうか（最初は false = 隠す）
  bool _isUiVisible = false;

  final List<Color> _colors = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    _initPath();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  Future<void> _initPath() async {
    final directory = await getApplicationDocumentsDirectory();
    setState(() {
      _docsDir = directory.path;
    });
  }

  String t(String key) {
    return Lang.data[_language]?[key] ?? key;
  }

  // 設定パネル（変更なし）
  void _showSettingsPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPanelState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 600,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('settings'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Text(t('language'),
                        style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: Lang.codes.length,
                        itemBuilder: (context, index) {
                          final code = Lang.codes[index];
                          final isSelected = code == _language;
                          return GestureDetector(
                            onTap: () {
                              setPanelState(() => _language = code);
                              setState(() => _language = code);
                            },
                            child: Container(
                              alignment: Alignment.center,
                              margin: const EdgeInsets.only(right: 10),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              decoration: BoxDecoration(
                                color:
                                    isSelected ? Colors.blue : Colors.grey[800],
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: Colors.white, width: 1),
                              ),
                              child: Text(Lang.names[code]!,
                                  style: const TextStyle(color: Colors.white)),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(color: Colors.grey),
                    SwitchListTile(
                      title: Text(t('use_24h'),
                          style: const TextStyle(color: Colors.white)),
                      value: _is24Hour,
                      onChanged: (value) {
                        setPanelState(() => _is24Hour = value);
                        setState(() => _is24Hour = value);
                      },
                    ),
                    SwitchListTile(
                      title: Text(t('show_seconds'),
                          style: const TextStyle(color: Colors.white)),
                      value: _showSeconds,
                      onChanged: (value) {
                        setPanelState(() => _showSeconds = value);
                        setState(() => _showSeconds = value);
                      },
                    ),
                    Text(t('text_color'),
                        style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 10),
                    _buildColorPicker((color) {
                      setPanelState(() => _numColor = color);
                      setState(() => _numColor = color);
                    }),
                    const SizedBox(height: 10),
                    Text(t('bg_color'),
                        style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 10),
                    _buildColorPicker((color) {
                      setPanelState(() => _bgColor = color);
                      setState(() => _bgColor = color);
                    }),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildColorPicker(Function(Color) onSelect) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _colors.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => onSelect(_colors[index]),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _colors[index],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 350,
          child: Column(
            children: [
              Text(t('edit_menu_title'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          foregroundColor: Colors.white),
                      child:
                          Text("$index", style: const TextStyle(fontSize: 24)),
                      onPressed: () {
                        Navigator.pop(context);
                        _goToEditScreen(index);
                      },
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: Text(t('edit_all'),
                      style: const TextStyle(color: Colors.white)),
                  onPressed: () {
                    Navigator.pop(context);
                    _goToEditScreen(null);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _goToEditScreen(int? targetNumber) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NumberCreator(targetNumber: targetNumber, language: _language),
      ),
    );
    if (_docsDir != null) {
      for (int i = 0; i < 10; i++) {
        final file = File('$_docsDir/num_$i.png');
        if (await file.exists()) {
          await FileImage(file).evict();
        }
      }
    }
    setState(() {});
  }

  // ==================================================
  // ★ここからUI（見た目）の作成
  // ==================================================
  @override
  Widget build(BuildContext context) {
    int displayHour = _now.hour;
    if (!_is24Hour) {
      displayHour = _now.hour % 12;
      if (displayHour == 0) displayHour = 12;
    }

    return Scaffold(
      backgroundColor: _bgColor,
      // AppBar（上のバー）は削除しました

      // 画面全体をタッチ可能にする
      body: GestureDetector(
        // タッチされたら UIの表示/非表示 を切り替える
        onTap: () {
          setState(() {
            _isUiVisible = !_isUiVisible;
          });
        },
        // Stack: 要素を重ねる（時計の上にボタンを乗せる）
        child: Stack(
          children: [
            // ------------------------
            // 1. 一番下の層：時計
            // ------------------------
            Center(
              child: _docsDir == null
                  ? const CircularProgressIndicator()
                  : FittedBox(
                      fit: BoxFit.contain,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildDigit(displayHour ~/ 10),
                          _buildDigit(displayHour % 10),
                          _buildColon(),
                          _buildDigit(_now.minute ~/ 10),
                          _buildDigit(_now.minute % 10),
                          if (_showSeconds) ...[
                            _buildColon(),
                            _buildDigit(_now.second ~/ 10),
                            _buildDigit(_now.second % 10),
                          ],
                          if (!_is24Hour)
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 10, bottom: 20, right: 10),
                              child: Text(
                                _now.hour >= 12 ? "PM" : "AM",
                                style: TextStyle(
                                  color: _numColor,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),

            // ------------------------
            // 2. 上の層：操作ボタン（設定・編集）
            // ------------------------
            // AnimatedOpacity: 表示/非表示をフワッと切り替える
            AnimatedOpacity(
              opacity: _isUiVisible ? 1.0 : 0.0, // trueなら不透明(見える)、falseなら透明
              duration: const Duration(milliseconds: 300), // 0.3秒かけて変化
              child: SafeArea(
                child: Stack(
                  children: [
                    // 右上の設定ボタン（歯車）
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        icon: const Icon(Icons.settings, size: 40), // 少し大きくした
                        color: _numColor.withOpacity(0.7), // 少し透けさせる
                        onPressed: _isUiVisible
                            ? _showSettingsPanel
                            : null, // 見えてない時は押せないようにする
                      ),
                    ),

                    // 右下の編集ボタン（鉛筆）
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: FloatingActionButton(
                        backgroundColor: Colors.white.withOpacity(0.9),
                        child: const Icon(Icons.edit, color: Colors.black),
                        onPressed: _isUiVisible
                            ? _showEditMenu
                            : null, // 見えてない時は押せないようにする
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigit(int number) {
    final path = '$_docsDir/num_$number.png';
    final file = File(path);
    return Container(
      width: 70,
      height: 140,
      alignment: Alignment.center,
      child: !file.existsSync()
          ? Text('$number', style: TextStyle(color: _numColor, fontSize: 40))
          : Image.file(file,
              fit: BoxFit.contain,
              key: UniqueKey(),
              color: _numColor,
              colorBlendMode: BlendMode.srcIn),
    );
  }

  Widget _buildColon() {
    return Container(
      height: 140,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Text(":",
          style: TextStyle(
              color: _numColor,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              height: 1.0)),
    );
  }
}

// ==========================================
// 2. 数字を書く画面（太さ変更機能つき！）
// ==========================================
class NumberCreator extends StatefulWidget {
  final int? targetNumber;
  final String language;

  const NumberCreator({super.key, this.targetNumber, required this.language});

  @override
  State<NumberCreator> createState() => _NumberCreatorState();
}

class _NumberCreatorState extends State<NumberCreator> {
  // ★初期の太さは 6.0
  double _strokeWidth = 6.0;

  late SignatureController _controller;
  late int _currentNumber;

  @override
  void initState() {
    super.initState();
    _currentNumber = widget.targetNumber ?? 0;

    // コントローラーの初期化（変数の太さを使う）
    _controller = SignatureController(
      penStrokeWidth: _strokeWidth,
      penColor: Colors.white,
      exportBackgroundColor: Colors.transparent,
    );
  }

  String t(String key) {
    return Lang.data[widget.language]?[key] ?? key;
  }

  Future<void> _saveAndNext() async {
    if (_controller.isEmpty) return;
    final Uint8List? data = await _controller.toPngBytes();
    if (data != null) {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/num_$_currentNumber.png';
      await File(path).writeAsBytes(data);

      if (widget.targetNumber != null) {
        Navigator.pop(context);
      } else {
        setState(() {
          if (_currentNumber < 9) {
            _currentNumber++;
            _controller.clear();
          } else {
            Navigator.pop(context);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String buttonText = t('next');
    if (widget.targetNumber != null || _currentNumber == 9) {
      buttonText = t('done');
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("${t('write_num')} '$_currentNumber'"),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ★追加：太さ調整スライダー
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Text(
                  "${t('pen_width')}: ${_strokeWidth.toInt()}",
                  style: const TextStyle(color: Colors.white),
                ),
                Slider(
                  value: _strokeWidth,
                  min: 3.0,
                  max: 20.0,
                  activeColor: Colors.white,
                  inactiveColor: Colors.grey[800],
                  onChanged: (value) {
                    setState(() {
                      _strokeWidth = value;
                      _controller = SignatureController(
                        penStrokeWidth: value, // 新しい太さをセット
                        penColor: Colors.white,
                        exportBackgroundColor: Colors.transparent,
                        points: _controller.points, // ★重要：今までの線をコピーして引き継ぐ
                      );
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2)),
            child: Signature(
              controller: _controller,
              width: 150,
              height: 300,
              backgroundColor: Colors.grey[800]!,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            t('canvas_hint'),
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Text(
            widget.targetNumber != null ? t('single_msg') : t('all_msg'),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _controller.clear(),
                child: Text(t('clear')),
              ),
              ElevatedButton(
                onPressed: _saveAndNext,
                child: Text(buttonText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. 言語データ（辞書）
// ==========================================
class Lang {
  static const List<String> codes = [
    'en',
    'es',
    'fr',
    'it',
    'pt',
    'ru',
    'de',
    'ja',
    'ko',
    'zh_Hans',
    'zh_Hant',
    'th',
    'vi',
    'hi',
    'ar'
  ];

  static const Map<String, String> names = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'it': 'Italiano',
    'pt': 'Português',
    'ru': 'Русский',
    'de': 'Deutsch',
    'ja': '日本語',
    'ko': '한국어',
    'zh_Hans': '简体中文',
    'zh_Hant': '繁體中文',
    'th': 'ไทย',
    'vi': 'Tiếng Việt',
    'hi': 'हिन्दी',
    'ar': 'العربية'
  };

  static const Map<String, Map<String, String>> data = {
    'en': {
      'settings': 'Settings',
      'use_24h': '24-Hour Clock',
      'show_seconds': 'Show Seconds',
      'text_color': 'Text Color',
      'bg_color': 'Background Color',
      'language': 'Language',
      'edit_menu_title': 'Select number to edit',
      'edit_all': 'Rewrite all (0-9)',
      'write_num': 'Write number',
      'clear': 'Clear',
      'next': 'Next',
      'done': 'Done',
      'single_msg': 'Rewrite only this number',
      'all_msg': 'Write all numbers in order',
      'canvas_hint': 'Draw large in the box',
      'pen_width': 'Pen Thickness', // ★追加
    },
    'es': {
      'settings': 'Ajustes',
      'use_24h': 'Reloj de 24 horas',
      'show_seconds': 'Mostrar segundos',
      'text_color': 'Color del texto',
      'bg_color': 'Color de fondo',
      'language': 'Idioma',
      'edit_menu_title': 'Seleccionar número',
      'edit_all': 'Reescribir todo (0-9)',
      'write_num': 'Escribir número',
      'clear': 'Borrar',
      'next': 'Siguiente',
      'done': 'Hecho',
      'single_msg': 'Reescribir solo este',
      'all_msg': 'Escribir todos en orden',
      'canvas_hint': 'Dibuja grande en la caja',
      'pen_width': 'Grosor del lápiz', // ★追加
    },
    'fr': {
      'settings': 'Paramètres',
      'use_24h': 'Format 24h',
      'show_seconds': 'Afficher les secondes',
      'text_color': 'Couleur du texte',
      'bg_color': 'Couleur de fond',
      'language': 'Langue',
      'edit_menu_title': 'Choisir le numéro',
      'edit_all': 'Tout réécrire (0-9)',
      'write_num': 'Écrire le numéro',
      'clear': 'Effacer',
      'next': 'Suivant',
      'done': 'Fait',
      'single_msg': 'Réécrire celui-ci',
      'all_msg': 'Écrire tout dans l\'ordre',
      'canvas_hint': 'Dessinez grand dans la boîte',
      'pen_width': 'Épaisseur du trait', // ★追加
    },
    'it': {
      'settings': 'Impostazioni',
      'use_24h': 'Formato 24 ore',
      'show_seconds': 'Mostra secondi',
      'text_color': 'Colore testo',
      'bg_color': 'Colore sfondo',
      'language': 'Lingua',
      'edit_menu_title': 'Seleziona numero',
      'edit_all': 'Riscrivi tutto (0-9)',
      'write_num': 'Scrivi numero',
      'clear': 'Cancella',
      'next': 'Avanti',
      'done': 'Fatto',
      'single_msg': 'Riscrivi solo questo',
      'all_msg': 'Scrivi tutto in ordine',
      'canvas_hint': 'Disegna grande nel box',
      'pen_width': 'Spessore penna', // ★追加
    },
    'pt': {
      'settings': 'Configurações',
      'use_24h': 'Formato 24 horas',
      'show_seconds': 'Mostrar segundos',
      'text_color': 'Cor do texto',
      'bg_color': 'Cor de fundo',
      'language': 'Idioma',
      'edit_menu_title': 'Selecionar número',
      'edit_all': 'Reescrever tudo (0-9)',
      'write_num': 'Escrever número',
      'clear': 'Limpar',
      'next': 'Próximo',
      'done': 'Feito',
      'single_msg': 'Reescrever apenas este',
      'all_msg': 'Escrever tudo em ordem',
      'canvas_hint': 'Desenhe grande na caixa',
      'pen_width': 'Espessura da caneta', // ★追加
    },
    'ru': {
      'settings': 'Настройки',
      'use_24h': '24-часовой формат',
      'show_seconds': 'Показывать секунды',
      'text_color': 'Цвет текста',
      'bg_color': 'Цвет фона',
      'language': 'Язык',
      'edit_menu_title': 'Выберите число',
      'edit_all': 'Переписать все (0-9)',
      'write_num': 'Напишите число',
      'clear': 'Очистить',
      'next': 'Далее',
      'done': 'Готово',
      'single_msg': 'Переписать только это',
      'all_msg': 'Написать все по порядку',
      'canvas_hint': 'Рисуйте крупно в рамке',
      'pen_width': 'Толщина пера', // ★追加
    },
    'de': {
      'settings': 'Einstellungen',
      'use_24h': '24-Stunden-Format',
      'show_seconds': 'Sekunden anzeigen',
      'text_color': 'Textfarbe',
      'bg_color': 'Hintergrundfarbe',
      'language': 'Sprache',
      'edit_menu_title': 'Zahl auswählen',
      'edit_all': 'Alles neu schreiben (0-9)',
      'write_num': 'Nummer schreiben',
      'clear': 'Löschen',
      'next': 'Weiter',
      'done': 'Fertig',
      'single_msg': 'Nur dieses neu schreiben',
      'all_msg': 'Alles der Reihe nach schreiben',
      'canvas_hint': 'Groß in den Kasten zeichnen',
      'pen_width': 'Stiftstärke', // ★追加
    },
    'ja': {
      'settings': '設定',
      'use_24h': '24時間表記',
      'show_seconds': '秒を表示する',
      'text_color': '文字の色',
      'bg_color': '背景の色',
      'language': '言語 (Language)',
      'edit_menu_title': '編集する数字を選んでください',
      'edit_all': '0から9まで全部書き直す',
      'write_num': '数字を書く',
      'clear': 'クリア',
      'next': '次へ',
      'done': '完了',
      'single_msg': 'これだけ書き直して保存します',
      'all_msg': '順番にすべての数字を書きます',
      'canvas_hint': '縦長の枠いっぱいに大きく書いてください',
      'pen_width': 'ペンの太さ', // ★追加
    },
    'ko': {
      'settings': '설정',
      'use_24h': '24시간 형식',
      'show_seconds': '초 표시',
      'text_color': '텍스트 색상',
      'bg_color': '배경 색상',
      'language': '언어',
      'edit_menu_title': '편집할 숫자 선택',
      'edit_all': '모두 다시 쓰기 (0-9)',
      'write_num': '숫자 쓰기',
      'clear': '지우기',
      'next': '다음',
      'done': '완료',
      'single_msg': '이 숫자만 다시 쓰기',
      'all_msg': '순서대로 모두 쓰기',
      'canvas_hint': '상자에 크게 그리세요',
      'pen_width': '펜 굵기', // ★追加
    },
    'zh_Hans': {
      'settings': '设置',
      'use_24h': '24小时制',
      'show_seconds': '显示秒数',
      'text_color': '文字颜色',
      'bg_color': '背景颜色',
      'language': '语言',
      'edit_menu_title': '选择要编辑的数字',
      'edit_all': '全部重写 (0-9)',
      'write_num': '写数字',
      'clear': '清除',
      'next': '下一步',
      'done': '完成',
      'single_msg': '仅重写此数字',
      'all_msg': '按顺序书写所有',
      'canvas_hint': '在框内画大一点',
      'pen_width': '笔画粗细', // ★追加
    },
    'zh_Hant': {
      'settings': '設置',
      'use_24h': '24小時制',
      'show_seconds': '顯示秒數',
      'text_color': '文字顏色',
      'bg_color': '背景顏色',
      'language': '語言',
      'edit_menu_title': '選擇要編輯的數字',
      'edit_all': '全部重寫 (0-9)',
      'write_num': '寫數字',
      'clear': '清除',
      'next': '下一步',
      'done': '完成',
      'single_msg': '僅重寫此數字',
      'all_msg': '按順序書寫所有',
      'canvas_hint': '在框內畫大一點',
      'pen_width': '筆畫粗細', // ★追加
    },
    'th': {
      'settings': 'การตั้งค่า',
      'use_24h': 'รูปแบบ 24 ชั่วโมง',
      'show_seconds': 'แสดงวินาที',
      'text_color': 'สีข้อความ',
      'bg_color': 'สีพื้นหลัง',
      'language': 'ภาษา',
      'edit_menu_title': 'เลือกตัวเลข',
      'edit_all': 'เขียนใหม่ทั้งหมด (0-9)',
      'write_num': 'เขียนตัวเลข',
      'clear': 'ล้าง',
      'next': 'ถัดไป',
      'done': 'เสร็จสิ้น',
      'single_msg': 'เขียนใหม่เฉพาะอันนี้',
      'all_msg': 'เขียนทั้งหมดตามลำดับ',
      'canvas_hint': 'วาดให้ใหญ่เต็มกล่อง',
      'pen_width': 'ความหนาของปากกา', // ★追加
    },
    'vi': {
      'settings': 'Cài đặt',
      'use_24h': 'Định dạng 24 giờ',
      'show_seconds': 'Hiển thị giây',
      'text_color': 'Màu văn bản',
      'bg_color': 'Màu nền',
      'language': 'Ngôn ngữ',
      'edit_menu_title': 'Chọn số để sửa',
      'edit_all': 'Viết lại tất cả (0-9)',
      'write_num': 'Viết số',
      'clear': 'Xóa',
      'next': 'Tiếp theo',
      'done': 'Xong',
      'single_msg': 'Chỉ viết lại số này',
      'all_msg': 'Viết tất cả theo thứ tự',
      'canvas_hint': 'Vẽ lớn trong khung',
      'pen_width': 'Độ dày bút', // ★追加
    },
    'hi': {
      'settings': 'सेटिंग',
      'use_24h': '24-घंटे का प्रारूप',
      'show_seconds': 'सेकंड दिखाएं',
      'text_color': 'टेक्स्ट का रंग',
      'bg_color': 'बैकग्राउंड का रंग',
      'language': 'भाषा',
      'edit_menu_title': 'नंबर चुनें',
      'edit_all': 'सभी को फिर से लिखें (0-9)',
      'write_num': 'नंबर लिखें',
      'clear': 'साफ़ करें',
      'next': 'अगला',
      'done': 'हो गया',
      'single_msg': 'केवल इसे फिर से लिखें',
      'all_msg': 'क्रम में सभी लिखें',
      'canvas_hint': 'बॉक्स में बड़ा लिखें',
      'pen_width': 'पेन की मोटाई', // ★追加
    },
    'ar': {
      'settings': 'الإعدادات',
      'use_24h': 'نظام 24 ساعة',
      'show_seconds': 'عرض الثواني',
      'text_color': 'لون النص',
      'bg_color': 'لون الخلفية',
      'language': 'اللغة',
      'edit_menu_title': 'اختر الرقم',
      'edit_all': 'أعد كتابة الكل (0-9)',
      'write_num': 'اكتب الرقم',
      'clear': 'مسح',
      'next': 'التالي',
      'done': 'تم',
      'single_msg': 'أعد كتابة هذا فقط',
      'all_msg': 'اكتب الكل بالترتيب',
      'canvas_hint': 'ارسم بشكل كبير في المربع',
      'pen_width': 'سمك القلم', // ★追加
    },
  };
}
