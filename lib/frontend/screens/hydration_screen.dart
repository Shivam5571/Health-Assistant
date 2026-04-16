import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data'; // Vibration pattern ke liye
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Packages
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart'; 

// --- BACKGROUND ACTION HANDLER ---
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  if (notificationResponse.actionId == 'snooze_action') {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    final now = tz.TZDateTime.now(tz.local);
    final snoozeTime = now.add(const Duration(minutes: 10));

    final Int64List vibrationPattern = Int64List.fromList([
      0, 1000, 500, 1000, 500, 1000, 500, 1000, 500, 1000
    ]);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'hydration_alarm_channel_v16', // Updated Channel ID v16
      'Pani Pivanu Reminders v16',
      channelDescription: 'Vibration only reminders for hydration',
      importance: Importance.max,
      priority: Priority.high,
      color: const Color(0xFF38B6FF),
      playSound: false, 
      enableVibration: true,
      vibrationPattern: vibrationPattern, 
      visibility: NotificationVisibility.public, 
      category: AndroidNotificationCategory.alarm, 
      audioAttributesUsage: AudioAttributesUsage.alarm,
      fullScreenIntent: true,
      actions: [
        const AndroidNotificationAction('drink_action', 'Pani Piyo 💧', showsUserInterface: true, cancelNotification: true),
        const AndroidNotificationAction('snooze_action', '10 Min Snooze 💤', showsUserInterface: false, cancelNotification: true),
      ],
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      999,
      'Snooze: Pani pivanu baki chhe! ⏰', 
      'Jaldi pani piyo, sharir ne jarur chhe! 💧', 
      snoozeTime,
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails(presentSound: false)),
      androidScheduleMode: AndroidScheduleMode.alarmClock, 
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Timezone initialize karvu (India Time)
  tz.initializeTimeZones();
  // Do not force a specific zone here; use device's local timezone (tz.local)
  
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDark') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        bool isDark = currentMode == ThemeMode.dark;
        return MaterialApp(
          title: 'Hydration nu Reminder',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          home: HydrationScreen(isDarkMode: isDark), 
        );
      },
    );
  }
}

// --- NOTIFICATION NI SEVA (NOTIFICATION SERVICE) ---
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<String> _actionStreamController = StreamController<String>.broadcast();
  Stream<String> get actionStream => _actionStreamController.stream;

  Future<void> init() async {
    // Ensure timezone database is initialized. Do NOT force a zone here;
    // use the device-local zone `tz.local` when scheduling.
    try {
      tz.initializeTimeZones();
      debugPrint('Timezone database initialized; tz.local=${tz.local.name}');
    } catch (e) {
      debugPrint('Failed to initialize timezone DB: $e');
    }
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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
        if (response.actionId == 'drink_action') {
          _actionStreamController.add('drink');
        } else if (response.actionId == 'snooze_action') {
          _actionStreamController.add('snooze');
        } else {
          _actionStreamController.add('navigate');
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create Android notification channel with vibration enabled so scheduled
    // alarms use it reliably on Android 8+ devices.
    if (Platform.isAndroid) {
      final androidImpl = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'hydration_alarm_channel_v16',
        'Pani Pivanu Reminders v16',
        description: 'Vibration only reminders for hydration',
        importance: Importance.max,
        playSound: false,
        enableVibration: true,
      );
      await androidImpl?.createNotificationChannel(channel);
    }
  }

  Future<void> requestPermissions() async {
    await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();
    await Permission.ignoreBatteryOptimizations.request();

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
      // Manual check for exact alarms
      final isGranted = await Permission.scheduleExactAlarm.isGranted;
      if (!isGranted) {
        await Permission.scheduleExactAlarm.request();
      }
      await androidImplementation?.requestFullScreenIntentPermission();
    }
  }

  // Turant Check Karne Ke Liye
  Future<void> showImmediateTest() async {
    final Int64List vibrationPattern = Int64List.fromList([
      0, 1000, 500, 1000, 500, 1000, 500, 1000, 500, 1000       
    ]);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'hydration_alarm_channel_v16', 
      'Pani Pivanu Reminders v16',
      channelDescription: 'Vibration only reminders for hydration',
      importance: Importance.max,
      priority: Priority.high,
      color: const Color(0xFF38B6FF),
      fullScreenIntent: true, 
      playSound: false, 
      enableVibration: true,
      vibrationPattern: vibrationPattern, 
      visibility: NotificationVisibility.public, 
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      actions: [
        const AndroidNotificationAction('drink_action', 'Pani Piyo 💧', showsUserInterface: true, cancelNotification: true),
      ],
    );

    await flutterLocalNotificationsPlugin.show(
      888,
      'Turant Test! 🚀',
      'Kya notification aaya aur phone vibrate hua? 📱',
      NotificationDetails(android: androidDetails, iOS: const DarwinNotificationDetails(presentSound: false)),
    );
  }

  // Returns true if success, false if OS blocked it
  Future<bool> scheduleTestAlarms() async {
    await cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    debugPrint('scheduleTestAlarms: using tz.local=${tz.local.name}, now=$now');

    if (Platform.isAndroid) {
      final isGranted = await Permission.scheduleExactAlarm.isGranted;
      if (!isGranted) {
        await openAppSettings();
        return false;
      }
    }
    
    final Int64List vibrationPattern = Int64List.fromList([
      0, 1000, 500, 1000, 500, 1000, 500, 1000, 500, 1000       
    ]);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'hydration_alarm_channel_v16', 
      'Pani Pivanu Reminders v16',
      channelDescription: 'Vibration only reminders for hydration',
      importance: Importance.max,
      priority: Priority.high,
      color: const Color(0xFF38B6FF),
      fullScreenIntent: true, 
      playSound: false, 
      enableVibration: true,
      vibrationPattern: vibrationPattern, 
      visibility: NotificationVisibility.public, 
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      actions: [
        const AndroidNotificationAction('drink_action', 'Pani Piyo 💧', showsUserInterface: true, cancelNotification: true),
        const AndroidNotificationAction('snooze_action', '10 Min Snooze 💤', showsUserInterface: false, cancelNotification: true),
      ],
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(presentSound: false),
    );

    List<int> secondsDelay = [15, 30];
    
    for (int i = 0; i < secondsDelay.length; i++) {
      try {
        final scheduledTime = now.add(Duration(seconds: secondsDelay[i]));
        debugPrint("Scheduling Test Alarm at: $scheduledTime (zone=${tz.local.name})");
        await flutterLocalNotificationsPlugin.zonedSchedule(
          800 + i, 
          'Test Reminder ${i+1} ⏰', 
          'Vibration aayi! 💧', 
          scheduledTime, 
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.alarmClock, 
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint("Error scheduling test: $e");
        return false; 
      }
    }
    return true; 
  }

  Future<bool> scheduleReminders(List<TimeOfDay> schedule, String bodyText) async {
    await cancelAll();
    int id = 100;
    
    final Int64List vibrationPattern = Int64List.fromList([
      0, 1000, 500, 1000, 500, 1000, 500, 1000, 500, 1000       
    ]);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'hydration_alarm_channel_v16', 
      'Pani Pivanu Reminders v16',
      channelDescription: 'Vibration only reminders for hydration',
      importance: Importance.max,
      priority: Priority.high,
      color: const Color(0xFF38B6FF),
      fullScreenIntent: true, 
      playSound: false, 
      enableVibration: true,
      vibrationPattern: vibrationPattern, 
      visibility: NotificationVisibility.public, 
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      actions: [
        const AndroidNotificationAction('drink_action', 'Pani Piyo 💧', showsUserInterface: true, cancelNotification: true),
        const AndroidNotificationAction('snooze_action', '10 Min Snooze 💤', showsUserInterface: false, cancelNotification: true),
      ],
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(presentSound: false),
    );

    final now = tz.TZDateTime.now(tz.local);
    debugPrint('scheduleReminders: using tz.local=${tz.local.name}, now=$now');

    // Fixing the TZDateTime calculation to ensure it matches precisely
    for (var time in schedule) {
      var scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute,
      );

      // Buffer check: if scheduled time is in the past or within the next 60s,
      // push to tomorrow to avoid immediate firing when user opens app close to the time.
      if (scheduledDate.isBefore(now.add(const Duration(seconds: 60)))) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
        debugPrint('Adjusted scheduledDate into next day to avoid immediate trigger: $scheduledDate');
      }

      try {
        debugPrint("Scheduling Reminder at: $scheduledDate (zone=${tz.local.name})");
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id++, 
          'Hydration nu Reminder ⏰', 
          bodyText, 
          scheduledDate, 
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.alarmClock, 
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e) {
        debugPrint("Error scheduling notification: $e");
        return false; 
      }
    }
    return true; 
  }

  // Silent status banner for tray
  Future<void> showUpcomingNotification(String timeStr) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'upcoming_channel_silent_v2', 
      'Hydration Status Banner',
      channelDescription: 'Non-interruptive banner for next reminder',
      importance: Importance.low, 
      priority: Priority.low,
      ongoing: true, 
      playSound: false,
      enableVibration: false, 
      color: Color(0xFF38B6FF),
    );

    await flutterLocalNotificationsPlugin.show(
      1, 
      'Hydration Tracker 💧',
      'Aaglu pani pivanu reminder: $timeStr vagye',
      const NotificationDetails(android: androidDetails),
    );
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}

// --- HYDRATION SCREEN ---
class HydrationScreen extends StatefulWidget {
  final bool isDarkMode;
  const HydrationScreen({super.key, this.isDarkMode = false});

  @override
  State<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends State<HydrationScreen> with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<String>? _actionSubscription;
  
  String _gender = "Purush";
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _sleepTime = const TimeOfDay(hour: 23, minute: 0);
  bool _remindersEnabled = true;
  
  int _dailyGoal = 3500;
  int _intake = 0;
  List<TimeOfDay> _schedulePreview = [];
  bool _isLoading = true;
  String _currentDateKey = "";
  String _nextReminderTime = "No active reminders";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentDateKey = _getTodayKey();
    _initialize();
    
    _actionSubscription = _notificationService.actionStream.listen((action) {
      if (action == 'drink') {
        _updateIntake(250);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Pani umerayu! Shabaash 💧"),
              backgroundColor: const Color(0xFF38B6FF),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else if (action == 'snooze') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Reminder 10 minute mate snooze thayu 💤")),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _actionSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData(); 
    }
  }

  Future<void> _initialize() async {
    await _notificationService.init();
    await _notificationService.requestPermissions();
    await _loadData();
    setState(() => _isLoading = false);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _currentDateKey = _getTodayKey();
    
    setState(() {
      String profileGender = prefs.getString('user_gender') ?? "Purush";
      _gender = prefs.getString('h_gender') ?? profileGender;
      
      _dailyGoal = prefs.getInt('h_goal') ?? (_gender == "Stri" ? 2700 : 3500);
      _remindersEnabled = prefs.getBool('h_reminders') ?? true;
      _intake = prefs.getInt('h_intake_$_currentDateKey') ?? 0;
      
      final wakeH = prefs.getInt('h_wake_h') ?? 7;
      final wakeM = prefs.getInt('h_wake_m') ?? 0;
      _wakeTime = TimeOfDay(hour: wakeH, minute: wakeM);

      final sleepH = prefs.getInt('h_sleep_h') ?? 23;
      final sleepM = prefs.getInt('h_sleep_m') ?? 0;
      _sleepTime = TimeOfDay(hour: sleepH, minute: sleepM);
    });
    await _generateSchedule();
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
    
    await _generateSchedule();
  }

  Future<void> _updateIntake(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayKey();

    if (_currentDateKey != today) {
      _intake = 0;
      _currentDateKey = today;
    }

    setState(() {
      _intake = (_intake + amount).clamp(0, 10000);
    });
    await prefs.setInt('h_intake_$_currentDateKey', _intake);
  }

  Future<void> _resetIntake() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _intake = 0;
    });
    await prefs.setInt('h_intake_$_currentDateKey', 0);
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return "${now.year}${now.month}${now.day}";
  }

  void _calculateGoal() {
    setState(() {
      switch (_gender) {
        case "Purush": _dailyGoal = 3500; break;
        case "Stri": _dailyGoal = 2700; break;
        default: _dailyGoal = 3000; break;
      }
    });
    _saveData();
  }

  Future<void> _generateSchedule() async {
    final startMin = _wakeTime.hour * 60 + _wakeTime.minute;
    var endMin = _sleepTime.hour * 60 + _sleepTime.minute;
    if (endMin < startMin) endMin += 24 * 60;

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

    _updateNextReminderText();

    if (_remindersEnabled) {
      bool success = await _notificationService.scheduleReminders(_schedulePreview, "Pani pivanu time thai gayo chhe! Jaldi karo! 💧");
      if (success && _nextReminderTime != "No active reminders") {
        _notificationService.showUpcomingNotification(_nextReminderTime);
      }
    } else {
      _notificationService.cancelAll();
    }
  }

  void _updateNextReminderText() {
    if (!_remindersEnabled || _schedulePreview.isEmpty) {
      setState(() {
        _nextReminderTime = "No active reminders";
      });
      return;
    }

    final now = TimeOfDay.now();
    TimeOfDay? nextTime;

    for (var time in _schedulePreview) {
      if (time.hour > now.hour || (time.hour == now.hour && time.minute > now.minute)) {
        nextTime = time;
        break;
      }
    }

    nextTime ??= _schedulePreview.first;

    setState(() {
      _nextReminderTime = nextTime!.format(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.isDarkMode ? const Color(0xFF0F1115) : const Color(0xFFF4F7FA);
    final Color textColor = widget.isDarkMode ? Colors.white : const Color(0xFF1E2029);
    final Color subTextColor = widget.isDarkMode ? Colors.white60 : const Color(0xFF7A809B);
    final Color cardColor = widget.isDarkMode ? const Color(0xFF1A1D24) : Colors.white;
    const Color primaryColor = Color(0xFF38B6FF); 

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CircularProgressIndicator(color: primaryColor))
      );
    }

    double progress = (_intake / _dailyGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Hydration Tracker", style: TextStyle(fontWeight: FontWeight.w800, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_rounded, color: textColor),
            onPressed: () => _showConfigSheet(bgColor, cardColor, textColor, subTextColor, primaryColor),
          )
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            if (_remindersEnabled && _nextReminderTime != "No active reminders")
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: primaryColor, size: 20),
                    const SizedBox(width: 10),
                    Text("Aaglu Reminder: ", style: TextStyle(color: subTextColor, fontWeight: FontWeight.w600)),
                    Text(_nextReminderTime, style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),

            Center(
              child: AnimatedWaterBody(
                progress: progress, 
                isDarkMode: widget.isDarkMode,
                gender: _gender, 
              ),
            ),

            const SizedBox(height: 30),
            
            Text(
              "${(progress * 100).toInt()}% Pani Pidu",
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Text(
              "$_intake / $_dailyGoal ml",
              style: TextStyle(fontSize: 16, color: subTextColor, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: _waterButton(250, Icons.local_drink_rounded, "Glass", cardColor, textColor, subTextColor, primaryColor)),
                const SizedBox(width: 16),
                Expanded(child: _waterButton(500, Icons.water_drop_rounded, "Bottle", cardColor, textColor, subTextColor, primaryColor)),
              ],
            ),

            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _remindersEnabled ? "Aaj nu Schedule" : "Reminders Bandh Chhe",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor),
                ),
                if (_remindersEnabled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${_schedulePreview.length} Tipa",
                      style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  )
              ],
            ),
            const SizedBox(height: 20),
            
            _remindersEnabled
            ? ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _schedulePreview.length,
                itemBuilder: (context, index) {
                  final time = _schedulePreview[index];
                  final now = TimeOfDay.now();
                  bool isPassed = (time.hour < now.hour) || (time.hour == now.hour && time.minute < now.minute);
                  return _buildReminderCard(time, isPassed, cardColor, textColor, subTextColor, primaryColor);
                },
              )
            : Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardColor, 
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.notifications_off_rounded, size: 50, color: subTextColor.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    Text("Pani Pita Raho!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 4),
                    Text("Settings mathi reminders chalu karo.", style: TextStyle(color: subTextColor)),
                  ],
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(TimeOfDay time, bool isPassed, Color cardColor, Color textColor, Color subTextColor, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: widget.isDarkMode ? Colors.black.withOpacity(0.2) : primaryColor.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
        border: Border.all(
          color: isPassed 
              ? (widget.isDarkMode ? Colors.white10 : Colors.grey.shade200)
              : primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPassed ? Colors.green.withOpacity(0.15) : primaryColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPassed ? Icons.check_circle_rounded : Icons.water_drop_rounded,
              color: isPassed ? Colors.green : primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time.format(context),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isPassed ? subTextColor : textColor,
                    decoration: isPassed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPassed ? "Puru Thayu" : "Aavnaru Reminder",
                  style: TextStyle(
                    fontSize: 13,
                    color: isPassed ? Colors.green : subTextColor,
                    fontWeight: isPassed ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "250ml",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isPassed ? subTextColor : primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _waterButton(int amount, IconData icon, String label, Color cardColor, Color textColor, Color subTextColor, Color primaryColor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _updateIntake(amount);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: widget.isDarkMode ? Colors.black.withOpacity(0.3) : primaryColor.withOpacity(0.08), 
              blurRadius: 20, 
              offset: const Offset(0, 8)
            )
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: primaryColor),
            ),
            const SizedBox(height: 14),
            Text("+$amount ml", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: textColor)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 13, color: subTextColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showConfigSheet(Color bgColor, Color cardColor, Color textColor, Color subTextColor, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, top: 24, left: 24, right: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 6,
                    decoration: BoxDecoration(color: subTextColor.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
                  )
                ),
                const SizedBox(height: 24),
                Text("Settings (Gothavani)", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor)),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.bolt_rounded, color: Colors.blue),
                    label: const Text("Turant Test Karo (Immediate) ⚡", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide(color: Colors.blue.withOpacity(0.5), width: 1.5),
                    ),
                    onPressed: () async {
                      await _notificationService.showImmediateTest();
                      if (context.mounted) {
                        Navigator.pop(context); 
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.redAccent),
                    label: const Text("Aaj nu Pani Reset Karo", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide(color: Colors.redAccent.withOpacity(0.5), width: 1.5),
                    ),
                    onPressed: () {
                      _resetIntake();
                      setModalState((){});
                      setState((){});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Pani nu tracking reset thai gayu! 💧"), backgroundColor: Colors.redAccent)
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                Text("Ling (Aapmele Shape ane Goal set kare chhe)", style: TextStyle(color: subTextColor, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  children: ["Purush", "Stri", "Anya"].map((g) => Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: ChoiceChip(
                      label: Text(g, style: TextStyle(fontWeight: FontWeight.bold, color: _gender == g ? Colors.white : textColor)),
                      selected: _gender == g,
                      backgroundColor: cardColor,
                      selectedColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (selected) {
                        if (selected) {
                          setModalState(() => _gender = g);
                          setState(() {}); 
                          _calculateGoal(); 
                        }
                      },
                    ),
                  )).toList(),
                ),
                
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Roj nu Pani nu Limit", style: TextStyle(color: subTextColor, fontWeight: FontWeight.w700)),
                    Text("$_dailyGoal ml", style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: primaryColor,
                    inactiveTrackColor: primaryColor.withOpacity(0.2),
                    thumbColor: primaryColor,
                    overlayColor: primaryColor.withOpacity(0.1),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: _dailyGoal.toDouble(),
                    min: 1000,
                    max: 6000,
                    divisions: 50, 
                    label: "$_dailyGoal ml",
                    onChanged: (val) {
                      setModalState(() => _dailyGoal = val.toInt());
                      setState((){}); 
                    },
                    onChangeEnd: (val) {
                      _saveData(); 
                    },
                  ),
                ),

                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: _timePickerBtn("Uthvano Samay", _wakeTime, Icons.wb_sunny_rounded, cardColor, textColor, subTextColor, primaryColor, (t) {
                        setModalState(() => _wakeTime = t);
                        _saveData();
                      }),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _timePickerBtn("Suvano Samay", _sleepTime, Icons.nights_stay_rounded, cardColor, textColor, subTextColor, primaryColor, (t) {
                        setModalState(() => _sleepTime = t);
                        _saveData();
                      }),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                Container(
                  decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
                  child: SwitchListTile(
                    title: Text("Reminders Chalu Karo", style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
                    secondary: Icon(Icons.alarm_on_rounded, color: primaryColor),
                    value: _remindersEnabled,
                    activeColor: primaryColor,
                    onChanged: (val) {
                      setModalState(() => _remindersEnabled = val);
                      _saveData();
                    },
                  ),
                ),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(18),
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 5,
                      shadowColor: primaryColor.withOpacity(0.4),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Puru Thayu", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _timePickerBtn(String label, TimeOfDay time, IconData icon, Color cardColor, Color textColor, Color subTextColor, Color primaryColor, Function(TimeOfDay) onPicked) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: time);
        if (picked != null) onPicked(picked);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: subTextColor, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(time.format(context), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- ANIMATED HUMAN ANATOMY WATER FILL WIDGET ---
class AnimatedWaterBody extends StatefulWidget {
  final double progress;
  final bool isDarkMode;
  final String gender;
  
  const AnimatedWaterBody({
    super.key, 
    required this.progress, 
    required this.isDarkMode,
    required this.gender,
  });

  @override
  State<AnimatedWaterBody> createState() => _AnimatedWaterBodyState();
}

class _AnimatedWaterBodyState extends State<AnimatedWaterBody> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 2500)
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  CustomClipper<Path> _getClipper() {
    if (widget.gender.toLowerCase() == 'stri') {
      return FemaleClipper();
    }
    return MaleClipper();
  }

  @override
  Widget build(BuildContext context) {
    const double width = 130;
    const double height = 280;
    final currentClipper = _getClipper();

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipPath(
            key: ValueKey(widget.gender + '_bg'), 
            clipper: currentClipper,
            child: Container(
              color: widget.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade300,
            ),
          ),
          
          ClipPath(
            key: ValueKey(widget.gender + '_fg'), 
            clipper: currentClipper,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(width, height),
                  painter: WaterWavePainter(
                    progress: widget.progress,
                    phase: _waveController.value * 2 * pi,
                  ),
                );
              },
            ),
          ),

          CustomPaint(
            key: ValueKey(widget.gender + '_outline'), 
            size: const Size(width, height),
            painter: HumanOutlinePainter(
              isDarkMode: widget.isDarkMode,
              clipper: currentClipper,
            ),
          ),
        ],
      ),
    );
  }
}

class MaleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.addOval(Rect.fromCircle(center: Offset(w * 0.5, h * 0.12), radius: w * 0.14));
    path.moveTo(w * 0.4, h * 0.26); 
    path.lineTo(w * 0.6, h * 0.26); 
    path.quadraticBezierTo(w * 0.85, h * 0.26, w * 0.85, h * 0.4); 
    path.lineTo(w * 0.85, h * 0.65); 
    path.quadraticBezierTo(w * 0.85, h * 0.7, w * 0.78, h * 0.7); 
    path.lineTo(w * 0.75, h * 0.45); 
    path.lineTo(w * 0.72, h * 0.6); 
    path.lineTo(w * 0.72, h * 0.95); 
    path.quadraticBezierTo(w * 0.72, h * 1.0, w * 0.62, h * 1.0); 
    path.lineTo(w * 0.55, h * 0.65); 
    path.quadraticBezierTo(w * 0.5, h * 0.6, w * 0.45, h * 0.65);
    path.lineTo(w * 0.38, h * 1.0); 
    path.quadraticBezierTo(w * 0.28, h * 1.0, w * 0.28, h * 0.95); 
    path.lineTo(w * 0.28, h * 0.6); 
    path.lineTo(w * 0.25, h * 0.45); 
    path.lineTo(w * 0.22, h * 0.7); 
    path.quadraticBezierTo(w * 0.15, h * 0.7, w * 0.15, h * 0.65); 
    path.lineTo(w * 0.15, h * 0.4); 
    path.quadraticBezierTo(w * 0.15, h * 0.26, w * 0.4, h * 0.26); 
    path.close();
    return path;
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => oldClipper.runtimeType != runtimeType;
}

class FemaleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.addOval(Rect.fromCircle(center: Offset(w * 0.5, h * 0.12), radius: w * 0.13));
    path.moveTo(w * 0.43, h * 0.25);
    path.lineTo(w * 0.57, h * 0.25);
    path.quadraticBezierTo(w * 0.8, h * 0.26, w * 0.8, h * 0.4); 
    path.lineTo(w * 0.8, h * 0.65); 
    path.quadraticBezierTo(w * 0.8, h * 0.7, w * 0.73, h * 0.7); 
    path.lineTo(w * 0.7, h * 0.45); 
    path.quadraticBezierTo(w * 0.6, h * 0.55, w * 0.72, h * 0.65); 
    path.lineTo(w * 0.72, h * 0.95); 
    path.quadraticBezierTo(w * 0.72, h * 1.0, w * 0.62, h * 1.0); 
    path.lineTo(w * 0.55, h * 0.68); 
    path.quadraticBezierTo(w * 0.5, h * 0.64, w * 0.45, h * 0.68);
    path.lineTo(w * 0.38, h * 1.0); 
    path.quadraticBezierTo(w * 0.28, h * 1.0, w * 0.28, h * 0.95); 
    path.lineTo(w * 0.28, h * 0.65); 
    path.quadraticBezierTo(w * 0.4, h * 0.55, w * 0.3, h * 0.45); 
    path.lineTo(w * 0.27, h * 0.7); 
    path.quadraticBezierTo(w * 0.2, h * 0.7, w * 0.2, h * 0.65); 
    path.lineTo(w * 0.2, h * 0.4); 
    path.quadraticBezierTo(w * 0.2, h * 0.26, w * 0.43, h * 0.25); 
    path.close();
    return path;
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => oldClipper.runtimeType != runtimeType;
}

class WaterWavePainter extends CustomPainter {
  final double progress;
  final double phase;

  WaterWavePainter({required this.progress, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final w = size.width;
    final h = size.height;
    final baseY = h - (progress * h);
    final amplitude = progress >= 1.0 ? 0.0 : h * 0.015;

    final pathBg = Path();
    pathBg.moveTo(0, h);
    pathBg.lineTo(0, baseY);
    for (double i = 0; i <= w; i++) {
      pathBg.lineTo(i, baseY + sin((i / w * 2 * pi) + phase + pi) * amplitude); 
    }
    pathBg.lineTo(w, h);
    pathBg.close();
    
    final paintBg = Paint()..color = const Color(0xFF38B6FF).withOpacity(0.4);
    canvas.drawPath(pathBg, paintBg);

    final pathFg = Path();
    pathFg.moveTo(0, h);
    pathFg.lineTo(0, baseY);
    for (double i = 0; i <= w; i++) {
      pathFg.lineTo(i, baseY + sin((i / w * 2 * pi) + phase) * amplitude);
    }
    pathFg.lineTo(w, h);
    pathFg.close();

    final paintFg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF38B6FF), Color(0xFF0077B6)],
      ).createShader(Rect.fromLTWH(0, baseY, w, h - baseY));

    canvas.drawPath(pathFg, paintFg);
  }

  @override
  bool shouldRepaint(covariant WaterWavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.phase != phase;
  }
}

class HumanOutlinePainter extends CustomPainter {
  final bool isDarkMode;
  final CustomClipper<Path> clipper;
  
  HumanOutlinePainter({required this.isDarkMode, required this.clipper});

  @override
  void paint(Canvas canvas, Size size) {
    final path = clipper.getClip(size);
    final paint = Paint()
      ..color = isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
      
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HumanOutlinePainter old) => 
      old.clipper.runtimeType != clipper.runtimeType || old.isDarkMode != isDarkMode;
}