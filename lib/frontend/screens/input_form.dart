import 'package:flutter/material.dart';
import 'chat_screen.dart'; // AI Assistant screen

class InputFormScreen extends StatefulWidget {
  final bool isDarkMode; // Passed from Home screen

  const InputFormScreen({super.key, this.isDarkMode = false});

  @override
  State<InputFormScreen> createState() => _InputFormScreenState();
}

class _InputFormScreenState extends State<InputFormScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final ageCtrl = TextEditingController();
  final heightCtrl = TextEditingController();
  final weightCtrl = TextEditingController();

  String goal = "weight_loss";
  String gender = "Male";
  String activityLevel = "sedentary";

  bool loading = false;
  Map<String, dynamic>? result;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Entrance Animation setup
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    ageCtrl.dispose();
    heightCtrl.dispose();
    weightCtrl.dispose();
    super.dispose();
  }

  void submit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    // Auto Calculation Logic (Instant result via local calculation)
    Future.delayed(const Duration(milliseconds: 600), () {
      double h = double.parse(heightCtrl.text); // cm
      double w = double.parse(weightCtrl.text); // kg
      int a = int.parse(ageCtrl.text); // years

      // 1. BMI Calculation
      double heightInMeters = h / 100;
      double bmi = w / (heightInMeters * heightInMeters);

      // Ideal Weight Range Calculation
      double minIdealWeight = 18.5 * (heightInMeters * heightInMeters);
      double maxIdealWeight = 24.9 * (heightInMeters * heightInMeters);

      // 2. BMR Calculation (Mifflin-St Jeor Equation - most precise)
      double bmr = (10 * w) + (6.25 * h) - (5 * a);
      if (gender == "Male") {
        bmr += 5;
      } else {
        bmr -= 161;
      }

      // 3. TDEE Calculation (Total Daily Energy Expenditure)
      double multiplier = 1.2; // Default sedentary
      switch (activityLevel) {
        case "light": multiplier = 1.375; break;
        case "moderate": multiplier = 1.55; break;
        case "active": multiplier = 1.725; break;
        case "extra": multiplier = 1.9; break;
      }
      double tdee = bmr * multiplier;

      // 4. Health Category & Message Generation
      String category = "";
      Color categoryColor = Colors.grey;
      if (bmi < 18.5) {
        category = "Underweight";
        categoryColor = Colors.blueAccent;
      } else if (bmi < 24.9) {
        category = "Normal Weight";
        categoryColor = Colors.green;
      } else if (bmi < 29.9) {
        category = "Overweight";
        categoryColor = Colors.orange;
      } else {
        category = "Obese";
        categoryColor = Colors.redAccent;
      }

      int targetCalories = tdee.round();
      String actionPlan = "";

      if (goal == "weight_loss") {
        targetCalories -= 500; // 500 kcal deficit
        actionPlan = "Maintain a daily deficit of ~500 calories to safely lose 0.5kg per week.\n\nFocus on high-protein, nutrient-dense whole foods and stay hydrated.";
      } else if (goal == "weight_gain") {
        targetCalories += 500; // 500 kcal surplus
        actionPlan = "Consume a surplus of ~500 calories to safely build mass.\n\nCombine this diet with progressive strength training for muscle growth.";
      } else {
        actionPlan = "Your current diet is well-balanced. Keep consuming your TDEE calories to maintain your current physique.";
      }

      if (mounted) {
        setState(() {
          result = {
            "bmi": bmi.toStringAsFixed(1),
            "category": category,
            "categoryColor": categoryColor,
            "minWeight": minIdealWeight.toStringAsFixed(1),
            "maxWeight": maxIdealWeight.toStringAsFixed(1),
            "bmr": bmr.round().toString(),
            "tdee": tdee.round().toString(),
            "targetCalories": targetCalories.toString(),
            "actionPlan": actionPlan,
            "goal": goal, // Added goal for AI Context
          };
          loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDarkMode;
    final Color bgColor = isDark ? const Color(0xFF0F1115) : const Color(0xFFF4F7FA);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E2029);
    final Color subTextColor = isDark ? Colors.white60 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. Decorative Background Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withOpacity(isDark ? 0.1 : 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF6584).withOpacity(isDark ? 0.1 : 0.05),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar (Clean & Optimized)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
                      ),
                      Expanded(
                        child: Text(
                          "Health Scan",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // To balance the back button
                    ],
                  ),
                ),

                // Scrollable Body with Animation
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: result != null ? resultView(isDark, textColor, subTextColor) : formView(isDark, textColor, subTextColor),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget formView(bool isDark, Color textColor, Color subTextColor) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Analyze Your Body",
            style: TextStyle(
              fontSize: 28, 
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Enter your details to generate a complete health report and personalized plan.",
            style: TextStyle(fontSize: 15, color: subTextColor, height: 1.4),
          ),
          const SizedBox(height: 32),

          // Row 1: Age and Gender
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: ageCtrl,
                  label: "Age",
                  suffix: "yrs",
                  icon: Icons.cake_rounded,
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  value: gender,
                  label: "Gender",
                  icon: Icons.person_outline_rounded,
                  items: const [
                    DropdownMenuItem(value: "Male", child: Text("Male")),
                    DropdownMenuItem(value: "Female", child: Text("Female")),
                  ],
                  onChanged: (v) => setState(() => gender = v!),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Row 2: Height and Weight
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: heightCtrl,
                  label: "Height",
                  suffix: "cm",
                  icon: Icons.height_rounded,
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: weightCtrl,
                  label: "Weight",
                  suffix: "kg",
                  icon: Icons.monitor_weight_rounded,
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Activity Level
          _buildDropdown(
            value: activityLevel,
            label: "Activity Level",
            icon: Icons.directions_run_rounded,
            items: const [
              DropdownMenuItem(value: "sedentary", child: Text("Sedentary (Little/No Exercise)")),
              DropdownMenuItem(value: "light", child: Text("Lightly Active (1-3 days/week)")),
              DropdownMenuItem(value: "moderate", child: Text("Moderately Active (3-5 days/week)")),
              DropdownMenuItem(value: "active", child: Text("Very Active (6-7 days/week)")),
              DropdownMenuItem(value: "extra", child: Text("Extra Active (Physical Job)")),
            ],
            onChanged: (v) => setState(() => activityLevel = v!),
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // Goal
          _buildDropdown(
            value: goal,
            label: "Primary Goal",
            icon: Icons.flag_rounded,
            items: const [
              DropdownMenuItem(value: "weight_loss", child: Text("Weight Loss")),
              DropdownMenuItem(value: "weight_gain", child: Text("Weight Gain")),
              DropdownMenuItem(value: "maintain", child: Text("Maintain Weight")),
            ],
            onChanged: (v) => setState(() => goal = v!),
            isDark: isDark,
          ),

          const SizedBox(height: 40),

          // Calculate Button
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF4A00E0)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: loading ? null : submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: loading
                  ? const SizedBox(
                      width: 24, 
                      height: 24, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      "Calculate Metrics",
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget resultView(bool isDark, Color textColor, Color subTextColor) {
    double bmiVal = double.tryParse(result!['bmi'].toString()) ?? 0.0;
    final cardBgColor = isDark ? const Color(0xFF1A1D24) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            "Your Health Report",
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 1. Premium BMI Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1E2C), Color(0xFF2A2D3E)], 
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "BODY MASS INDEX",
                    style: TextStyle(
                      color: Colors.white54, 
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: result!['categoryColor'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: result!['categoryColor']),
                    ),
                    child: Text(
                      result!['category'],
                      style: TextStyle(
                        color: result!['categoryColor'],
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                result!['bmi'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Ideal Weight: ${result!['minWeight']} - ${result!['maxWeight']} kg",
                style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              
              // Visual Gradient BMI Bar
              Container(
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.green, Colors.orange, Colors.redAccent],
                    stops: [0.0, 0.33, 0.66, 1.0],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        double normalized = (bmiVal - 15) / (35 - 15);
                        normalized = normalized.clamp(0.0, 1.0);
                        return Container(
                          margin: EdgeInsets.only(left: (constraints.maxWidth - 12) * normalized),
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black87, width: 2),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("Underweight", style: TextStyle(color: Colors.white38, fontSize: 10)),
                  Text("Normal", style: TextStyle(color: Colors.white38, fontSize: 10)),
                  Text("Obese", style: TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. BMR & TDEE Row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: "BMR",
                value: "${result!['bmr']} kcal",
                subtitle: "Calories your body burns at complete rest.",
                icon: Icons.bedtime_rounded,
                iconColor: Colors.orangeAccent,
                bgColor: cardBgColor,
                textColor: textColor,
                borderColor: borderColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                title: "TDEE",
                value: "${result!['tdee']} kcal",
                subtitle: "Total calories burned including activity.",
                icon: Icons.directions_run_rounded,
                iconColor: Colors.tealAccent.shade400,
                bgColor: cardBgColor,
                textColor: textColor,
                borderColor: borderColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // 3. Target Calories / Action Plan Highlight
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.flag_circle_rounded, color: Color(0xFF6C63FF), size: 28),
                  const SizedBox(width: 12),
                  Text(
                    "Your Daily Target", 
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "${result!['targetCalories']} kcal / day",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF6C63FF)),
              ),
              const SizedBox(height: 12),
              Text(
                result!['actionPlan'],
                style: TextStyle(color: subTextColor, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // 4. AI Assistant Integration Button (PASSING DATA TO CHAT)
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () {
              // Pass Theme and Health Data to AI Chat!
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => ChatScreen(
                  isDarkMode: isDark,
                  healthData: result, // Sending calculated data to AI
                ))
              );
            },
            icon: const Icon(Icons.smart_toy_rounded, color: Colors.white),
            label: const Text(
              "Get AI Custom Diet Plan",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 5. Recalculate Button
        TextButton.icon(
          onPressed: () {
             setState(() => result = null);
             _controller.reset();
             _controller.forward();
          },
          icon: Icon(Icons.refresh_rounded, color: subTextColor),
          label: Text("Recalculate Metrics", style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _buildMetricCard({required String title, required String value, required String subtitle, required IconData icon, required Color iconColor, required Color bgColor, required Color textColor, required Color borderColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.3)),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? suffix,
    required IconData icon,
    required TextInputType keyboardType,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D24) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (v) => v!.isEmpty ? "Required" : null,
        style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 14),
          suffixText: suffix,
          suffixStyle: const TextStyle(color: Colors.grey, fontSize: 12),
          prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 20), 
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required dynamic value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem> items,
    required Function(dynamic) onChanged,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D24) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: DropdownButtonFormField(
        value: value,
        items: items,
        onChanged: onChanged,
        style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
        dropdownColor: isDark ? const Color(0xFF1A1D24) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}