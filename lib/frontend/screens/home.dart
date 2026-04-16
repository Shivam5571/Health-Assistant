import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ingredient_scanner_screen.dart'; 
import 'ai_assistant_screen.dart'; // <-- AI Assistant Chat Screen yahan import kar liya hai

// Note: In real app, ensure these imports are correct based on your project structure
// import 'input_form.dart';
// import 'hydration_screen.dart'; 
// import 'steps_screen.dart'; 

// DUMMY CLASSES to prevent errors if the files aren't present in this specific run.
// Remove these and uncomment your actual imports in your real project.
class InputFormScreen extends StatelessWidget { final bool isDarkMode; const InputFormScreen({super.key, required this.isDarkMode}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Input Form"))); }
class HydrationScreen extends StatelessWidget { final bool isDarkMode; const HydrationScreen({super.key, required this.isDarkMode}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Hydration"))); }
class StepsScreen extends StatelessWidget { final bool isDarkMode; const StepsScreen({super.key, required this.isDarkMode}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Steps"))); }


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Day / Night Mode ki State
  bool isDarkMode = false; 

  // Staggered Entry Animation Controllers
  late final AnimationController _animController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  late final Animation<double> _headerAnim = CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.5, curve: Curves.easeOutQuart));
  late final Animation<double> _heroAnim = CurvedAnimation(parent: _animController, curve: const Interval(0.2, 0.7, curve: Curves.easeOutQuart));
  late final Animation<double> _toolsAnim = CurvedAnimation(parent: _animController, curve: const Interval(0.4, 0.9, curve: Curves.easeOutQuart));
  late final Animation<double> _gridAnim = CurvedAnimation(parent: _animController, curve: const Interval(0.5, 1.0, curve: Curves.easeOutQuart));

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Theme ke hisaab se Premium Color Palette
    final Color bgColor = isDarkMode ? const Color(0xFF0F1115) : const Color(0xFFF4F7FA);
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF1E2029);
    final Color subTextColor = isDarkMode ? Colors.white60 : const Color(0xFF7A809B);
    final Color cardColor = isDarkMode ? const Color(0xFF1A1D24) : Colors.white;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(backgroundColor: bgColor, body: const Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;
        final String displayName = user?.displayName?.split(' ')[0] ?? "User";
        final String fullName = user?.displayName ?? "HealthFly User";
        final String email = user?.email ?? "user@healthfly.com";
        final String? photoUrl = user?.photoURL;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: bgColor, 
          
          // --- FROSTED GLASS DRAWER ---
          endDrawer: _buildPremiumDrawer(context, user, fullName, email, photoUrl, cardColor, textColor, subTextColor),

          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Animated Header
                    FadeTransition(
                      opacity: _headerAnim,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(_headerAnim),
                        child: _buildHeader(displayName, photoUrl, textColor, subTextColor),
                      ),
                    ),
                    
                    const SizedBox(height: 32),

                    // 2. Animated Hero Card (Deep Premium Aurora Background + Realistic Medical Beats)
                    FadeTransition(
                      opacity: _heroAnim,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(_heroAnim),
                        child: _buildHeroCard(context),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 3. Quick AI Tools
                    FadeTransition(
                      opacity: _toolsAnim,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(_toolsAnim),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Intelligent Tools",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildQuickToolCard(
                                    context, "Ask AI", "Health Assistant", Icons.auto_awesome_rounded, 
                                    const Color(0xFF6C63FF), cardColor, textColor, subTextColor,
                                    // <-- Yahan updated logic hai
                                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => AIAssistantScreen(isDarkMode: isDarkMode))),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildQuickToolCard(
                                    context, "Scan Food", "Check Ingredients", Icons.document_scanner_rounded, 
                                    const Color(0xFFFF6B6B), cardColor, textColor, subTextColor,
                                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => IngredientScannerScreen(isDarkMode: isDarkMode))),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 4. Daily Wellness Grid
                    FadeTransition(
                      opacity: _gridAnim,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(_gridAnim),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Daily Wellness",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 16),
                            
                            // Asymmetric Grid Look
                            Row(
                              children: [
                                Expanded(child: _buildStatCard(context, "Hydration", "Target: 2L", Icons.water_drop_rounded, const Color(0xFF38B6FF), cardColor, textColor, subTextColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => HydrationScreen(isDarkMode: isDarkMode))))),
                                const SizedBox(width: 16),
                                Expanded(child: _buildStatCard(context, "Steps", "Goal: 10k", Icons.directions_run_rounded, const Color(0xFFFF9F1C), cardColor, textColor, subTextColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => StepsScreen(isDarkMode: isDarkMode))))),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _buildStatCard(context, "Yoga", "Daily Asanas", Icons.self_improvement_rounded, const Color(0xFF9D4EDD), cardColor, textColor, subTextColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const YogaScreen())))),
                                const SizedBox(width: 16),
                                Expanded(child: _buildStatCard(context, "Breathe", "Pranayam", Icons.air_rounded, const Color(0xFF00B4D8), cardColor, textColor, subTextColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BreathingScreen())))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  // --- UI Components ---

  Widget _buildHeader(String name, String? photoUrl, Color textColor, Color subTextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello, $name",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Your health journey continues 🌟",
              style: TextStyle(
                fontSize: 14,
                color: subTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Smooth Day/Night Toggle
            GestureDetector(
              onTap: () {
                setState(() {
                  isDarkMode = !isDarkMode;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: isDarkMode ? Colors.transparent : Colors.grey.shade200, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => RotationTransition(
                    turns: child.key == const ValueKey('dark') 
                        ? Tween<double>(begin: 0.5, end: 1).animate(anim) 
                        : Tween<double>(begin: -0.5, end: 0).animate(anim),
                    child: ScaleTransition(scale: anim, child: child),
                  ),
                  child: Icon(
                    isDarkMode ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded, 
                    key: ValueKey(isDarkMode ? 'dark' : 'light'),
                    color: isDarkMode ? Colors.amberAccent : Colors.orangeAccent,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Profile Avatar with subtle glow
            BouncyCard(
              onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
                  ],
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
                  backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                  child: (photoUrl == null || photoUrl.isEmpty) ? Icon(Icons.person_rounded, color: subTextColor) : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Premium Hero Card (Aurora / Mesh Gradient feel + Deep Typography + Glossy Button)
  Widget _buildHeroCard(BuildContext context) {
    // Ekdum premium Navy/Purple shade
    final Color baseColor = isDarkMode ? const Color(0xFF171926) : const Color(0xFF291A5E);
    final Color orbColor1 = isDarkMode ? const Color(0xFF381F65) : const Color(0xFF53249E);
    final Color orbColor2 = isDarkMode ? const Color(0xFF132845) : const Color(0xFF360C69);
        
    return BouncyCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InputFormScreen(isDarkMode: isDarkMode))),
      child: Container(
        width: double.infinity,
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: baseColor,
          // Removed the dark/cheap border from day mode
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black.withOpacity(0.6) : baseColor.withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ], 
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // --- Aurora / Mesh Gradient Background Orbs ---
              Positioned(
                top: -50,
                left: -30,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: orbColor1.withOpacity(0.8),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                right: -20,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: orbColor2.withOpacity(0.9),
                  ),
                ),
              ),
              // Frosted glass effect
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(color: Colors.transparent),
                ),
              ),

              // --- Realistic Medical Heartbeat Line (ANIMATED ECG) Left-To-Right ---
              Positioned.fill(
                child: AnimatedECGLine(color: Colors.white.withOpacity(0.25)), 
              ),
              
              // --- Premium Pulsing 3D Highlighted Heart ---
              Positioned(
                right: 20,
                bottom: 30,
                child: PulsingWidget(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF416C).withOpacity(0.5), 
                          blurRadius: 35, 
                          spreadRadius: 2,
                        )
                      ]
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Base Glowing Gradient
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                            begin: Alignment.bottomRight,
                            end: Alignment.topLeft,
                          ).createShader(bounds),
                          child: const Icon(
                            Icons.favorite_rounded, 
                            size: 80, 
                            color: Colors.white,
                          ),
                        ),
                        // Top Highlight for 3D Glossy Effect
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [Colors.white.withOpacity(0.8), Colors.white.withOpacity(0.0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: const [0.0, 0.45],
                          ).createShader(bounds),
                          child: const Icon(
                            Icons.favorite_rounded, 
                            size: 80, 
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- Glassmorphism Overlay Content ---
              Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sleeker Premium Badge
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.5), 
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD700), size: 14),
                              SizedBox(width: 8),
                              Text(
                                "AI Powered",
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    
                    // Engaging & Punchy Text
                    Text(
                      "Unlock The Next Level\nOf Your Fitness",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))
                        ]
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            "Get instant BMI insights and personalized diet plans with AI.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                        // Sleek Interactive Glossy Glass Button
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.15),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1.2,
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.4),
                                    Colors.white.withOpacity(0.05),
                                  ],
                                ),
                              ),
                              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickToolCard(BuildContext context, String title, String subtitle, IconData icon, Color iconColor, Color cardColor, Color textColor, Color subTextColor, VoidCallback onTap) {
    return BouncyCard(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black.withOpacity(0.3) : iconColor.withOpacity(0.08), 
              blurRadius: 20, 
              offset: const Offset(0, 8)
            ),
          ],
          border: Border.all(color: isDarkMode ? Colors.white10 : Colors.grey.shade200, width: 1.5), // Subtle gray border
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12), 
                borderRadius: BorderRadius.circular(16)
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textColor)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, color: subTextColor, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String subtitle, IconData icon, Color iconColor, Color cardColor, Color textColor, Color subTextColor, VoidCallback onTap) {
    return BouncyCard(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.06), 
              blurRadius: 20, 
              offset: const Offset(0, 8)
            ),
          ],
          border: Border.all(color: isDarkMode ? Colors.white10 : Colors.grey.shade200, width: 1.5), // Subtle gray border
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                Icon(Icons.arrow_outward_rounded, color: isDarkMode ? Colors.white24 : Colors.grey.shade300, size: 20),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textColor)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: subTextColor, fontWeight: FontWeight.w500)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- PREMIUM FROSTED DRAWER ---
  Widget _buildPremiumDrawer(BuildContext context, User? user, String name, String email, String? photoUrl, Color cardColor, Color textColor, Color subTextColor) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Premium blur background
      child: Drawer(
        backgroundColor: cardColor.withOpacity(0.95), // Slight transparency
        elevation: 0,
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 30),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isDarkMode ? Colors.white10 : Colors.grey.shade200)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                      backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                      child: (photoUrl == null || photoUrl.isEmpty) ? Icon(Icons.person_rounded, size: 36, color: subTextColor) : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(email, style: TextStyle(fontSize: 14, color: subTextColor, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDrawerTile(Icons.person_outline_rounded, "My Profile", textColor, subTextColor, () {
              Navigator.pop(context);
              if (user != null) Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(user: user)));
            }),
            _buildDrawerTile(Icons.settings_outlined, "Settings", textColor, subTextColor, () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }),
            
            const Spacer(),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 32), child: Divider(color: Colors.grey, height: 1)),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog(context, cardColor, textColor);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                      SizedBox(width: 8),
                      Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, Color textColor, Color subTextColor, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      leading: Icon(icon, color: textColor, size: 26),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textColor)),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: subTextColor.withOpacity(0.5)),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, Color cardColor, Color textColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 10),
            Text("Log Out", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text("Are you sure you want to log out of HealthFly?", style: TextStyle(color: textColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
            },
            child: const Text("Log Out", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CUSTOM ANIMATED WIDGETS
// ============================================================================

/// Continuous Pulsing Animation for Hero Icon
class PulsingWidget extends StatefulWidget {
  final Widget child;
  const PulsingWidget({super.key, required this.child});

  @override
  State<PulsingWidget> createState() => _PulsingWidgetState();
}

class _PulsingWidgetState extends State<PulsingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}

/// Custom Bouncy Card for Premium Tap Effects
class BouncyCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const BouncyCard({super.key, required this.child, required this.onTap});

  @override
  State<BouncyCard> createState() => _BouncyCardState();
}

class _BouncyCardState extends State<BouncyCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 200),
    );
    // Smooth elastic-like feeling
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic, reverseCurve: Curves.easeOutQuad),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Realistic Medical ECG Line (Animated Background)
class AnimatedECGLine extends StatefulWidget {
  final Color color;
  const AnimatedECGLine({super.key, required this.color});

  @override
  State<AnimatedECGLine> createState() => _AnimatedECGLineState();
}

class _AnimatedECGLineState extends State<AnimatedECGLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Continuous scrolling animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // Speed of heartbeat scan
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: RealisticECGPainter(
            color: widget.color, 
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

/// Painter that draws a realistic PQRST complex wave
class RealisticECGPainter extends CustomPainter {
  final Color color;
  final double progress;
  
  RealisticECGPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5 // Elegant thin line
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final h = size.height;
    final w = size.width;
    
    // Width of one complete PQRST segment
    final segmentWidth = w * 0.45; 
    final int numSegments = 5; // Draw enough to fill screen plus buffer
    final double totalWidth = segmentWidth * numSegments;

    // Draw from negative to positive to allow left-to-right panning
    for (int i = -numSegments; i <= numSegments; i++) {
      final offsetX = i * segmentWidth;
      final midY = h * 0.65; // Baseline
      
      // Starting flat line (Isoelectric line)
      path.moveTo(offsetX, midY);
      path.lineTo(offsetX + segmentWidth * 0.15, midY); 
      
      // P Wave (small upward curve)
      path.quadraticBezierTo(offsetX + segmentWidth * 0.20, midY - (h * 0.08), offsetX + segmentWidth * 0.25, midY);
      
      // PR Segment (flat)
      path.lineTo(offsetX + segmentWidth * 0.30, midY);
      
      // Q Wave (small sharp dip)
      path.lineTo(offsetX + segmentWidth * 0.32, midY + (h * 0.05));
      
      // R Wave (Huge sharp spike UP)
      path.lineTo(offsetX + segmentWidth * 0.36, midY - (h * 0.45));
      
      // S Wave (Sharp dip DOWN below baseline)
      path.lineTo(offsetX + segmentWidth * 0.40, midY + (h * 0.15));
      
      // Back to baseline
      path.lineTo(offsetX + segmentWidth * 0.42, midY);
      
      // ST Segment (flat)
      path.lineTo(offsetX + segmentWidth * 0.50, midY);
      
      // T Wave (medium upward curve)
      path.quadraticBezierTo(offsetX + segmentWidth * 0.58, midY - (h * 0.12), offsetX + segmentWidth * 0.66, midY);
      
      // Ending flat line
      path.lineTo(offsetX + segmentWidth, midY);
    }

    // Clip bounds taaki box ke bahar na nikle
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h));
    
    // Animate: Move RIGHT (Left-To-Right). Progress goes 0 to 1
    canvas.translate(progress * totalWidth, 0);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant RealisticECGPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// ============================================================================
// OTHER INTELLIGENT SCANNERS & SCREENS
// ============================================================================

class YogaScreen extends StatelessWidget {
  const YogaScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yoga", style: TextStyle(fontWeight: FontWeight.bold))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            PulsingWidget(child: Icon(Icons.self_improvement_rounded, size: 80, color: Color(0xFF9D4EDD))),
            SizedBox(height: 20),
            Text("Daily Asanas coming soon!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class BreathingScreen extends StatelessWidget {
  const BreathingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Breathe", style: TextStyle(fontWeight: FontWeight.bold))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            PulsingWidget(child: Icon(Icons.air_rounded, size: 80, color: Color(0xFF00B4D8))),
            SizedBox(height: 20),
            Text("Pranayam features coming soon!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PROFILE & SETTINGS SCREENS
// ============================================================================

class ProfileScreen extends StatefulWidget {
  final User user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  
  String _selectedGender = "Male";
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName ?? "");
    _bioController = TextEditingController(text: "Fitness enthusiast & clean eater 🌱");
    _phoneController = TextEditingController(text: widget.user.phoneNumber ?? "+91 98765 43210"); 
    _ageController = TextEditingController(text: "25");
    _weightController = TextEditingController(text: "70");
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
          await user.updateDisplayName(_nameController.text.trim());
          await user.reload(); 
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Profile Updated Successfully!"), backgroundColor: Colors.green),
            );
            setState(() => _isEditing = false);
          }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = widget.user.photoURL;
    final email = widget.user.email ?? "";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("My Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
            child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_isEditing ? "Save" : "Edit", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          )
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                      backgroundColor: Colors.grey.shade100,
                      child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.person_rounded, size: 50, color: Colors.grey) : null,
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: BouncyCard(
                        onTap: (){},
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent, 
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2)
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    )
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileField("Full Name", _nameController, _isEditing, Icons.badge_rounded),
                  const SizedBox(height: 20),
                  
                  _buildProfileField("Phone Number", _phoneController, _isEditing, Icons.phone_rounded, isPhone: true),
                  const SizedBox(height: 20),

                  const Text("Gender", style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _isEditing ? Colors.white : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _isEditing ? Colors.blueAccent : Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedGender,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                        onChanged: _isEditing ? (newValue) {
                          setState(() => _selectedGender = newValue!);
                        } : null,
                        items: ["Male", "Female", "Other"].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Row(
                              children: [
                                Icon(value == "Male" ? Icons.male_rounded : value == "Female" ? Icons.female_rounded : Icons.transgender_rounded, color: Colors.grey, size: 20),
                                const SizedBox(width: 10),
                                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(child: _buildProfileField("Age", _ageController, _isEditing, Icons.cake_rounded, isNumber: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildProfileField("Weight (kg)", _weightController, _isEditing, Icons.monitor_weight_rounded, isNumber: true)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildProfileField("Bio", _bioController, _isEditing, Icons.edit_note_rounded, maxLines: 3),
                  const SizedBox(height: 20),
                  
                  Opacity(
                    opacity: 0.6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Email", style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.email_rounded, color: Colors.grey, size: 20),
                              const SizedBox(width: 10),
                              Text(email, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, TextEditingController controller, bool isEditable, IconData icon, {int maxLines = 1, bool isNumber = false, bool isPhone = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isEditable ? Colors.white : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isEditable ? Colors.blueAccent : Colors.grey.shade200, width: isEditable ? 1.5 : 1),
            boxShadow: isEditable ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.1), blurRadius: 10, offset: const Offset(0,4))] : [],
          ),
          child: TextField(
            controller: controller,
            enabled: isEditable,
            maxLines: maxLines,
            keyboardType: isNumber ? TextInputType.number : (isPhone ? TextInputType.phone : TextInputType.text),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: isEditable ? Colors.blueAccent : Colors.grey, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintText: "Enter $label",
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text("Account", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          _buildSettingsTile(
            context,
            Icons.person_outline_rounded,
            "Personal Details",
            onTap: () {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(user: user)));
              }
            },
          ),
          _buildSettingsTile(
            context,
            Icons.lock_outline_rounded,
            "Security",
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold)),
                  content: const Text("A password reset link will be sent to your email."),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reset link sent!"), backgroundColor: Colors.green));
                      },
                      child: const Text("Send", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
          _buildSettingsTile(
            context,
            Icons.notifications_none_rounded,
            "Notifications",
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (v) {
                setState(() => _notificationsEnabled = v);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_notificationsEnabled ? "Notifications Enabled" : "Notifications Disabled")),
                );
              },
              activeColor: Colors.blueAccent,
            ),
          ),
          
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text("Support & Info", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          _buildSettingsTile(
            context,
            Icons.help_outline_rounded,
            "Help Center",
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text("Help Center", style: TextStyle(fontWeight: FontWeight.bold)),
                  content: const SingleChildScrollView(
                    child: Text(
                      "Q: How do I track steps?\nA: Click on the Steps card on the home screen.\n\n"
                      "Q: Can I change my diet plan?\nA: Yes, use the AI Analysis tool to regenerate plans.\n\n"
                      "Q: Is my data safe?\nA: Yes, we use Firebase Security Rules to protect your data."
                    ),
                  ),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close", style: TextStyle(color: Colors.blueAccent)))],
                ),
              );
            }
          ),
          _buildSettingsTile(
            context,
            Icons.info_outline_rounded,
            "About HealthFly",
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "HealthFly",
                applicationVersion: "2.0.0",
                applicationIcon: const PulsingWidget(child: Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 40)),
                children: [
                  const SizedBox(height: 10),
                  const Text("HealthFly is your personal AI health companion. Built with Flutter, Firebase & Love.", style: TextStyle(fontSize: 14)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, IconData icon, String title, {Widget? trailing, VoidCallback? onTap}) {
    return BouncyCard(
      onTap: onTap ?? (){},
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 1), // Subtle gray border added
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ]
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.blueAccent, size: 22),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        ),
      ),
    );
  }
}