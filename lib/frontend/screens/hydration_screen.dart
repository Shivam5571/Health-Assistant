import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Packages
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

// --- NOTIFICATION SERVICE ---
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Stream to handle actions (Drink / Navigate)
  final StreamController<String> _actionStreamController = StreamController<String>.broadcast();
  Stream<String> get actionStream => _actionStreamController.stream;

  // Initialize
  Future<void> init() async {
    // Android Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Settings
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap or action button click
        if (response.actionId == 'drink_action') {
          _actionStreamController.add('drink');
        } else {
          _actionStreamController.add('navigate');
        }
        debugPrint("Notification Action: ${response.actionId}, Payload: ${response.payload}");
      },
    );
  }

  // Request Permissions (Android 13+)
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  // NEW: Feature to Test Notification Immediately
  Future<void> showInstantNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'hydration_channel',
      'Hydration Reminders',
      channelDescription: 'Reminders to drink water',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Test notification',
      color: Colors.blueAccent,
      playSound: true,
      // ACTION BUTTON ADDED
      actions: [
        AndroidNotificationAction(
          'drink_action', 
          'Drink Water 💧', 
          showsUserInterface: true, // Opens App
          cancelNotification: true
        ),
      ],
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      888, // Unique ID for test
      'Test Reminder ⏰',
      'Time to drink! Hurry up!',
      platformDetails,
      payload: 'hydration_screen',
    );
  }

  // Schedule Daily Reminders
  Future<void> scheduleReminders(
      List<TimeOfDay> schedule, String bodyText) async {
    // Clear old alarms
    await cancelAll();

    int id = 100;
    for (var time in schedule) {
      await _scheduleDaily(id++, time, bodyText);
    }
    debugPrint("Scheduled ${schedule.length} reminders.");
  }

  Future<void> _scheduleDaily(int id, TimeOfDay time, String body) async {
    final now = tz.TZDateTime.now(tz.local);
    
    // Create date for today at the specific time
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'hydration_channel',
      'Hydration Reminders',
      channelDescription: 'Reminders to drink water',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Time to hydrate',
      color: Colors.blueAccent,
      // ACTION BUTTON ADDED
      actions: [
        AndroidNotificationAction(
          'drink_action', 
          'Drink Water 💧', 
          showsUserInterface: true, // Opens App
          cancelNotification: true
        ),
      ],
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Hydration Reminder ⏰', // Updated Title
        'Time to drink! Hurry up! 💧', // Updated Body
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeats daily
        payload: 'hydration_screen',
      );
    } catch (e) {
      debugPrint("Error scheduling notification: $e");
    }
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}

// --- HYDRATION SCREEN ---

class HydrationScreen extends StatefulWidget {
  const HydrationScreen({super.key});

  @override
  State<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends State<HydrationScreen> with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<String>? _actionSubscription;
  
  // Settings
  String _gender = "Male";
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _sleepTime = const TimeOfDay(hour: 23, minute: 0);
  bool _remindersEnabled = true;
  
  // Progress
  int _dailyGoal = 3500;
  int _intake = 0;
  List<TimeOfDay> _schedulePreview = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
    
    // Listen for Notification Actions (Drink Button)
    _actionSubscription = _notificationService.actionStream.listen((action) {
      if (action == 'drink') {
        _updateIntake(250); // Add 250ml automatically
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Water added from notification! 💧"), backgroundColor: Colors.teal),
          );
        }
      }
      // Note: 'navigate' action just opens the app, which lands here naturally if this is the active screen
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _actionSubscription?.cancel();
    super.dispose();
  }

  // Refresh data when app comes to foreground (in case date changed)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData(); 
    }
  }

  Future<void> _initialize() async {
    // 1. Init Notifications
    await _notificationService.init();
    await _notificationService.requestPermissions();
    
    // 2. Load Persisted Data
    await _loadData();
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Settings
    setState(() {
      _gender = prefs.getString('h_gender') ?? "Male";
      _dailyGoal = prefs.getInt('h_goal') ?? 3500;
      _remindersEnabled = prefs.getBool('h_reminders') ?? true;
      _intake = prefs.getInt('h_intake_${_getTodayKey()}') ?? 0;
      
      final wakeH = prefs.getInt('h_wake_h') ?? 7;
      final wakeM = prefs.getInt('h_wake_m') ?? 0;
      _wakeTime = TimeOfDay(hour: wakeH, minute: wakeM);

      final sleepH = prefs.getInt('h_sleep_h') ?? 23;
      final sleepM = prefs.getInt('h_sleep_m') ?? 0;
      _sleepTime = TimeOfDay(hour: sleepH, minute: sleepM);
    });

    _generateSchedule();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('h_gender', _gender);
    await prefs.setInt('h_goal', _dailyGoal);
    await prefs.setBool('h_reminders', _remindersEnabled);
    await prefs.setInt('h_wake_h', _wakeTime.hour);
    await prefs.setInt('h_wake_m', _wakeTime.minute);
    await prefs.setInt('h_sleep_h', _sleepTime.hour);
    await prefs.setInt('h_sleep_m', _sleepTime.minute);
    
    _generateSchedule(); // Regenerate schedule on save
  }

  Future<void> _updateIntake(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _intake = (_intake + amount).clamp(0, 10000);
    });
    await prefs.setInt('h_intake_${_getTodayKey()}', _intake);
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return "${now.year}${now.month}${now.day}";
  }

  // --- LOGIC ---

  void _calculateGoal() {
    setState(() {
      switch (_gender) {
        case "Male": _dailyGoal = 3500; break;
        case "Female": _dailyGoal = 2700; break;
        default: _dailyGoal = 3000; break;
      }
    });
    _saveData();
  }

  void _generateSchedule() {
    final startMin = _wakeTime.hour * 60 + _wakeTime.minute;
    var endMin = _sleepTime.hour * 60 + _sleepTime.minute;
    if (endMin < startMin) endMin += 24 * 60; // Handle midnight crossover

    final activeDuration = endMin - startMin;
    const cupSize = 250;
    final cupsNeeded = (_dailyGoal / cupSize).ceil();

    _schedulePreview.clear();

    if (activeDuration > 0 && cupsNeeded > 0) {
      final interval = activeDuration ~/ cupsNeeded;
      
      for (int i = 0; i < cupsNeeded; i++) {
        final reminderMin = startMin + (interval * (i + 1));
        final hour = (reminderMin ~/ 60) % 24;
        final minute = reminderMin % 60;
        _schedulePreview.add(TimeOfDay(hour: hour, minute: minute));
      }
    }

    if (_remindersEnabled) {
      _notificationService.scheduleReminders(_schedulePreview, "Time to drink! Hurry up! 💧");
    } else {
      _notificationService.cancelAll();
    }
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    double progress = (_intake / _dailyGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Hydration", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.blueAccent),
            onPressed: _showConfigSheet,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Progress Circle
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 22,
                    backgroundColor: Colors.blue.shade50,
                    color: Colors.blueAccent,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      "${(progress * 100).toInt()}%",
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                    Text(
                      "$_intake / $_dailyGoal ml",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 40),

            // Quick Add Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _waterButton(250, Icons.local_drink, "Glass"),
                _waterButton(500, Icons.local_cafe, "Bottle"),
              ],
            ),

            const SizedBox(height: 40),

            // Schedule Info
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _remindersEnabled ? "Upcoming Reminders" : "Reminders Disabled",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            _remindersEnabled
            ? ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _schedulePreview.length,
                itemBuilder: (context, index) {
                  final time = _schedulePreview[index];
                  // Simple check if passed (not perfect for midnight crossover, but sufficient for UI)
                  final now = TimeOfDay.now();
                  bool isPassed = (time.hour < now.hour) || (time.hour == now.hour && time.minute < now.minute);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isPassed ? Icons.check_circle : Icons.access_time_filled,
                      color: isPassed ? Colors.green : Colors.blueAccent,
                    ),
                    title: Text(
                      time.format(context),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPassed ? Colors.grey : Colors.black,
                        decoration: isPassed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    trailing: const Text("250ml", style: TextStyle(color: Colors.grey)),
                  );
                },
              )
            : Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text("Enable reminders in settings")),
              ),
          ],
        ),
      ),
    );
  }

  Widget _waterButton(int amount, IconData icon, String label) {
    return InkWell(
      onTap: () => _updateIntake(amount),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade100),
          boxShadow: [
            BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: Colors.blueAccent),
            const SizedBox(height: 8),
            Text("+$amount ml", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // --- CONFIG SHEET ---

  void _showConfigSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Settings", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                // ADDED: TEST BUTTON HERE
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.notifications_active),
                    label: const Text("Test Notification Now"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: () async {
                      Navigator.pop(context); // Close sheet
                      await _notificationService.showInstantNotification();
                    },
                  ),
                ),
                const SizedBox(height: 20),

                const Text("Gender (Auto-set Goal)", style: TextStyle(color: Colors.grey)),
                Row(
                  children: ["Male", "Female", "Other"].map((g) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(g),
                      selected: _gender == g,
                      onSelected: (selected) {
                        if (selected) {
                          setModalState(() => _gender = g);
                          _calculateGoal(); // Updates state in parent
                        }
                      },
                    ),
                  )).toList(),
                ),
                
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: _timePickerBtn("Wake Up", _wakeTime, (t) {
                        setModalState(() => _wakeTime = t);
                        _saveData();
                      }),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _timePickerBtn("Sleep", _sleepTime, (t) {
                        setModalState(() => _sleepTime = t);
                        _saveData();
                      }),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Enable Reminders"),
                  value: _remindersEnabled,
                  activeColor: Colors.blueAccent,
                  onChanged: (val) {
                    setModalState(() => _remindersEnabled = val);
                    _saveData();
                  },
                ),
                
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blueAccent,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Done", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _timePickerBtn(String label, TimeOfDay time, Function(TimeOfDay) onPicked) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: time);
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(time.format(context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}