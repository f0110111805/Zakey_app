import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'dart:async';

void main() {
  runApp(const ZakeyApp());
}

class ZakeyApp extends StatelessWidget {
  const ZakeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zakey Assistant',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText speech = stt.SpeechToText();
  bool isListening = false;
  String lastWords = '';
  String status = 'دوس الزر واتكلم';
  List<Contact> _contacts = [];
  StreamSubscription<NotificationEvent>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await _requestPermissions();
    await _initTts();
    await _loadContacts();
    _initNotificationListener();
    _speak("مرحباً، أنا زاكي. جاهز لخدمتك");
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
      Permission.phone,
      Permission.contacts,
    ].request();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("ar-SA");
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> _loadContacts() async {
    if (await Permission.contacts.isGranted) {
      _contacts = await FlutterContacts.getContacts(withProperties: true);
    }
  }

  void _initNotificationListener() async {
    bool isRunning = await NotificationListenerService.isRunning;
    if (!isRunning) {
      await NotificationListenerService.requestPermission();
    }
    
    _notificationSubscription = NotificationListenerService.notificationsStream.listen((event) {
      if (event.packageName == "com.whatsapp") {
        setState(() {
          status = "رسالة جديدة من ${event.title}: ${event.content}";
        });
        _speak("وصلتك رسالة من ${event.title}. أقرأها ليك؟");
      }
    });
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  void _listen() async {
    if (!isListening) {
      bool available = await speech.initialize();
      if (available) {
        setState(() {
          isListening = true;
          status = "بتكلم... اتكلم هسي";
        });
        speech.listen(
          onResult: (result) {
            setState(() {
              lastWords = result.recognizedWords;
            });
          },
          localeId: 'ar_SA',
        );
      }
    } else {
      setState(() {
        isListening = false;
        status = "بفكر...";
      });
      speech.stop();
      _handleCommand(lastWords);
    }
  }

  Future<void> _handleCommand(String command) async {
    String cmd = command.toLowerCase();
    
    if (cmd.contains("اتصل")) {
      _callContact(cmd);
    } else if (cmd.contains("افتح واتساب")) {
      _openWhatsApp();
    } else if (cmd.contains("رد على الواتس") || cmd.contains("ارسل")) {
      _replyWhatsApp(cmd);
    } else {
      _speak("ما فهمت الأمر. قول تاني");
      setState(() => status = "دوس الزر واتكلم");
    }
  }

  Future<void> _callContact(String command) async {
    for (var contact in _contacts) {
      if (command.contains(contact.displayName.toLowerCase())) {
        if (contact.phones.isNotEmpty) {
          String number = contact.phones.first.number;
          _speak("بتصل على ${contact.displayName}");
          await launchUrl(Uri.parse("tel:$number"));
          setState(() => status = "دوس الزر واتكلم");
          return;
        }
      }
    }
    _speak("ما لقيت الاسم في جهات الاتصال");
    setState(() => status = "دوس الزر واتكلم");
  }

  Future<void> _openWhatsApp() async {
    _speak("بفتح ليك واتساب");
    await launchUrl(Uri.parse("https://wa.me/"));
    setState(() => status = "دوس الزر واتكلم");
  }

  Future<void> _replyWhatsApp(String command) async {
    // استخراج الرسالة بعد كلمة "قول"
    String message = "";
    if (command.contains("قول")) {
      message = command.split("قول")[1].trim();
    }
    
    if (message.isNotEmpty) {
      _speak("ح ارسل: $message");
      // الرد بتم عن طريق NotificationListenerService
      // هنا بنحتاج accessibility service كامل، لكن دي بداية
      setState(() => status = "جاهز للرد. افتح اشعار الواتس");
    } else {
      _speak("قول الرسالة بعد كلمة قول");
    }
    setState(() => status = "دوس الزر واتكلم");
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zakey مساعدك الصوتي')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(status, style: const TextStyle(fontSize: 20), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Text('قلت: $lastWords', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 40),
            FloatingActionButton.large(
              onPressed: _listen,
              child: Icon(isListening ? Icons.mic : Icons.mic_none, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('جرب تقول: اتصل لأحمد\nافتح واتساب\nرد على الواتس قول أنا جاي', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
