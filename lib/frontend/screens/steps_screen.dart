import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; // Data store karne ke liye

class StepsScreen extends StatefulWidget {
  final bool isDarkMode; // Day/Night Mode Passed from Home

  const StepsScreen({super.key, this.isDarkMode = false});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  late bool _isDark; // Local state for Day/Night
  bool _isTracking = false;
  int _steps = 0;
  double _distanceKm = 0.0;
  double _calories = 0.0;
  double _currentSpeed = 0.0; // km/h

  // Sensor Streams
  StreamSubscription<UserAccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  
  // Logic Variables
  DateTime? _lastStepTime;
  double _gyroMagnitude = 0.0; // Spinning check ke liye
  int _lastStepsCalculatedForSpeed = 0;
  Timer? _speedTimer;

  @override
  void initState() {
    super.initState();
    _isDark = widget.isDarkMode; // Init with passed value
    _loadSavedData(); // Purane steps load karo
  }

  @override
  void dispose() {
    _stopTracking();
    _saveData(); // App band hone se pehle save karo
    super.dispose();
  }

  // --- DATA STORAGE LOGIC ---
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Aaj ki date ka key banate hain taaki daily steps alag rahein
    String todayDate = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
    
    setState(() {
      _steps = prefs.getInt('steps_$todayDate') ?? 0;
      _distanceKm = _steps * 0.000762;
      _calories = _steps * 0.04;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    String todayDate = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
    await prefs.setInt('steps_$todayDate', _steps);
  }

  Future<void> _resetSteps() async {
    // Confirmation dialog before resetting
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDark ? const Color(0xFF1A1D24) : Colors.white,
        title: Text("Reset Steps?", style: TextStyle(color: _isDark ? Colors.white : Colors.black)),
        content: Text("Are you sure you want to start from 0?", style: TextStyle(color: _isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Reset", style: TextStyle(color: Colors.white))
          ),
        ],
      )
    );

    if (confirm == true) {
      setState(() {
        _steps = 0;
        _distanceKm = 0.0;
        _calories = 0.0;
        _currentSpeed = 0.0;
        _lastStepsCalculatedForSpeed = 0;
      });
      _saveData(); // Update stored 0
    }
  }

  // --- REAL HARDWARE SENSOR LOGIC ---
  void _toggleTracking() {
    if (_isTracking) {
      _stopTracking();
      _saveData(); // Pause par save kar lo
    } else {
      _startTracking();
    }
  }

  void _startTracking() {
    setState(() => _isTracking = true);
    
    _lastStepTime = DateTime.now();
    _lastStepsCalculatedForSpeed = _steps;

    // 1. Gyroscope Stream (Noise Cancellation / Anti-Spin Filter)
    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      _gyroMagnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    });

    // 2. Accelerometer Stream (Step Detection)
    _accelSubscription = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      if (!_isTracking) return;

      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      // 🔴 SENSITIVITY & SPIN FIX: 
      // accelMag > 1.5 (Walking)
      // gyroMagnitude < 2.5 (Spinning/Ghumna reject karne ke liye)
      if (magnitude > 1.5 && _gyroMagnitude < 2.5) {
        DateTime now = DateTime.now();
        // 350ms cooldown ensures ek time par multi-steps count na ho
        if (_lastStepTime == null || now.difference(_lastStepTime!).inMilliseconds > 350) {
          _lastStepTime = now;
          if (mounted) {
            setState(() {
              _steps++;
              _distanceKm = _steps * 0.000762; 
              _calories = _steps * 0.04;
            });

            // Har 10 kadam par silently data save karo
            if (_steps % 10 == 0) _saveData();
          }
        }
      }
    });

    // 3. Live Speed Calculator
    _speedTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isTracking || !mounted) return;
      
      int stepsTakenInInterval = _steps - _lastStepsCalculatedForSpeed;
      double distanceMetersInInterval = stepsTakenInInterval * 0.762;
      
      double speedMetersPerSec = distanceMetersInInterval / 2.0;
      double speedKmh = speedMetersPerSec * 3.6;

      setState(() {
        _currentSpeed = speedKmh;
        _lastStepsCalculatedForSpeed = _steps;
      });
    });
  }

  void _stopTracking() {
    setState(() {
      _isTracking = false;
      _currentSpeed = 0.0;
    });
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    _speedTimer?.cancel();
  }

  // --- UI BUILDING ---
  @override
  Widget build(BuildContext context) {
    // Local Dark Mode Colors
    final Color bgColor = _isDark ? const Color(0xFF0F1115) : const Color(0xFFF8F9FD);
    final Color cardColor = _isDark ? const Color(0xFF1A1D24) : Colors.white;
    final Color textColor = _isDark ? Colors.white : Colors.black87;
    final Color subTextColor = _isDark ? Colors.white54 : Colors.grey.shade600;
    final Color borderColor = _isDark ? Colors.white10 : Colors.transparent;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Hardware Step Tracker"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
        actions: [
          // Local Day/Night Toggle
          IconButton(
            icon: Icon(_isDark ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded, color: _isDark ? Colors.amberAccent : Colors.orangeAccent),
            onPressed: () {
              setState(() => _isDark = !_isDark);
            },
          ),
          // RESET BUTTON
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textColor),
            tooltip: "Reset Steps",
            onPressed: _resetSteps,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 1. Main Steps Status Card
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isTracking 
                      ? [const Color(0xFFFF9F1C), const Color(0xFFFF6B6B)] // Active
                      : [_isDark ? Colors.grey.shade800 : Colors.grey.shade400, _isDark ? Colors.grey.shade900 : Colors.grey.shade600], // Paused
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: (_isTracking ? const Color(0xFFFF9F1C) : Colors.grey).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    _isTracking ? Icons.directions_run_rounded : Icons.accessibility_new_rounded, 
                    color: Colors.white, 
                    size: 48
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _steps.toString(),
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const Text(
                    "TOTAL STEPS TODAY",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20)
                    ),
                    child: Text(
                      _isTracking ? "● TRACKING ACTIVE" : "PAUSED",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // 2. Hardware Stats Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStatItem(Icons.map_rounded, "${_distanceKm.toStringAsFixed(2)} km", "Distance", Colors.blueAccent, cardColor, textColor, subTextColor, borderColor),
                  _buildStatItem(Icons.local_fire_department_rounded, _calories.toStringAsFixed(0), "Calories", Colors.redAccent, cardColor, textColor, subTextColor, borderColor),
                  _buildStatItem(Icons.speed_rounded, "${_currentSpeed.toStringAsFixed(1)} km/h", "Live Speed", Colors.greenAccent.shade700, cardColor, textColor, subTextColor, borderColor),
                  _buildStatItem(Icons.explore_rounded, _isTracking ? "Active" : "Idle", "Anti-Spin Gyro", Colors.purpleAccent, cardColor, textColor, subTextColor, borderColor),
                ],
              ),
            ),

            // 3. Start/Stop Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _toggleTracking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTracking ? Colors.redAccent : const Color(0xFFFF9F1C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 5,
                  shadowColor: (_isTracking ? Colors.redAccent : const Color(0xFFFF9F1C)).withOpacity(0.5),
                ),
                child: Text(
                  _isTracking ? "STOP TRACKING" : "START HARDWARE SENSORS",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            
            // Sub Info
            Text(
              "Progress is auto-saved locally.",
              style: TextStyle(color: subTextColor, fontSize: 12),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color iconColor, Color cardColor, Color textColor, Color subTextColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}