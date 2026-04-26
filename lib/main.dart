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
        primarySwatch: Colors.green,
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
  late Stream<StepCount> _stepCountStream;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    if (await Permission.activityRecognition.request().isGranted) {
      _initPedometer();
    } else {
      setState(() => _steps = 'الاذن مرفوض');
    }
  }

  void _initPedometer() {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(onStepCount).onError(onStepCountError);
  }

  void onStepCount(StepCount event) {
    setState(() => _steps = event.steps.toString());
  }

  void onStepCountError(error) {
    setState(() => _steps = 'خطأ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تطبيق زاكي - عداد الخطوات'),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_walk, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text('عدد الخطوات اليوم', style: TextStyle(fontSize: 24)),
            Text(_steps, style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.green)),
            const Text('خطوة', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
