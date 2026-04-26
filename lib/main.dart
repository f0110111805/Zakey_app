import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const ZakeyApp());
}

class ZakeyApp extends StatelessWidget {
  const ZakeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zakey App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const StepCounterPage(),
    );
  }
}

class StepCounterPage extends StatefulWidget {
  const StepCounterPage({super.key});

  @override
  State<StepCounterPage> createState() => _StepCounterPageState();
}

class _StepCounterPageState extends State<StepCounterPage> {
  String _steps = '0';
  String _status = 'اضغط تفعيل الصلاحيات';
  bool _isGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    var status = await Permission.activityRecognition.status;
    if (status.isGranted) {
      _initPedometer();
    }
  }

  void _initPedometer() {
    Pedometer.stepCountStream.listen(_onStepCount).onError(_onError);
    setState(() {
      _isGranted = true;
      _status = 'جاهز - ابدأ المشي';
    });
  }

  void _onStepCount(StepCount event) {
    setState(() {
      _steps = event.steps.toString();
      _status = 'شغال ✅';
    });
  }

  void _onError(error) {
    setState(() {
      _status = 'خطأ: السنسور ما مدعوم';
    });
  }

  Future<void> _requestPermission() async {
    var status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      _initPedometer();
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _status = 'الصلاحية مرفوضة - افتح الإعدادات';
      });
      openAppSettings();
    } else {
      setState(() {
        _status = 'الصلاحية مرفوضة ❌';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Zakey - عداد الخطوات', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_walk,
              size: 100,
              color: _isGranted ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              'عدد الخطوات',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 10),
            Text(
              _steps,
              style: const TextStyle(
                fontSize: 90,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _isGranted ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _status,
                style: TextStyle(
                  fontSize: 16,
                  color: _isGranted ? Colors.green.shade800 : Colors.orange.shade800,
                ),
              ),
            ),
            const SizedBox(height: 50),
            if (!_isGranted)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: _requestPermission,
                icon: const Icon(Icons.security),
                label: const Text('تفعيل الصلاحيات', style: TextStyle(fontSize: 18)),
              ),
          ],
        ),
      ),
    );
  }
}
