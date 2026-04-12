import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // Gemini API package

class ChatScreen extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic>? healthData; // Health Scan mathi aavelo data

  const ChatScreen({super.key, this.isDarkMode = false, this.healthData});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<Map<String, dynamic>> messages = [];
  bool isLoading = false;
  String userName = "User";
  bool _isFirstMessage = true;

  // Gemini AI variables
  GenerativeModel? _model;
  ChatSession? _chatSession;

  // IMPORTANT: Aapki Gemini API Key yahan hai
  final String apiKey = "AIzaSyDxqGaPMNIW2pDaWRjhc6BbKsXPpoTbjM0"; 

  @override
  void initState() {
    super.initState();
    _initGemini();
  }

  // Gemini AI initialize karne ka function
  void _initGemini() {
    // Firebase se user ka naam lena
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.displayName != null && user.displayName!.isNotEmpty) {
      userName = user.displayName!.split(' ')[0];
    }

    if (apiKey.isEmpty || apiKey == "YOUR_GEMINI_API_KEY_HERE") {
      _sendInitialGreeting();
      return;
    }

    // Using gemini-1.5-flash which is the fastest and best free model for chat
    String systemInstructionText = "You are an expert Indian Nutritionist. The user's name is $userName. ";
    
    if (widget.healthData != null) {
      final d = widget.healthData!;
      systemInstructionText += "Their BMI is ${d['bmi']} (${d['category']}), Goal is ${d['goal']}, and target daily calories is ${d['targetCalories']} kcal. ";
    }
    
    systemInstructionText += "Provide a highly detailed, easy-to-understand daily diet routine strictly based on an Indian lifestyle (mentioning foods like Roti, Dal, Paneer, Oats, Idli, Dosa etc.). "
        "Also specify what foods to eat and what to avoid. Do not repeat their stats back to them unless asked. Be very conversational, empathetic, and professional. Always respond in English.";

    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(systemInstructionText),
      );
      _chatSession = _model!.startChat();
    } catch (e) {
      debugPrint("GenerativeModel Init Error: $e");
    }

    _sendInitialGreeting();
  }

  // First greeting message
  void _sendInitialGreeting() {
    if (widget.healthData != null) {
      final goal = widget.healthData!['goal'].toString().replaceAll('_', ' ').toUpperCase();
      final calories = widget.healthData!['targetCalories'];
      final bmi = widget.healthData!['bmi'];
      
      messages.add({
        "role": "ai", 
        "text": "Hi $userName, I have carefully reviewed your health report.\n\n📊 BMI: $bmi\n🎯 Goal: $goal\n🔥 Target: $calories kcal/day\n\nDo you have any other medical conditions (like Diabetes, Thyroid, PCOD)? You can also attach your blood reports using the 📎 icon below.\n\nTo create your personalized Indian diet routine, please tell me your preference (Veg/Non-Veg/Vegan)!",
        "isAttachment": false,
      });
    } else {
      messages.add({
        "role": "ai", 
        "text": "Hello $userName! I am your AI Health & Diet Assistant. How can I help you today?",
        "isAttachment": false,
      });
    }
    setState(() {});
  }

  // Report attach karne ka function (Simulated attachment logic, passing context to Gemini)
  void _attachReport() async {
    setState(() {
      messages.add({
        "role": "user", 
        "text": "📎 [Medical_Report.pdf] Attached",
        "isAttachment": true,
      });
      isLoading = true;
    });
    _scrollToBottom();

    if (_chatSession == null) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        isLoading = false;
        messages.add({
          "role": "ai", 
          "text": "⚠️ Real AI Setup Required!\n\nPlease put your valid Gemini API Key in the code to process this report.",
          "isAttachment": false,
        });
      });
      _scrollToBottom();
      return;
    }

    // Pure AI Logic for attachment handling
    try {
      final response = await _chatSession!.sendMessage(
        Content.text("SYSTEM INFO: The user has attached a simulated medical report. Please acknowledge it professionally and ask them about their dietary preferences to proceed with the Indian diet plan.")
      );

      if (!mounted) return;
      setState(() {
        isLoading = false;
        messages.add({
          "role": "ai", 
          "text": response.text ?? "I have noted your report. Please let me know your dietary preferences so we can build your Indian diet plan.",
          "isAttachment": false,
        });
      });
    } catch (e) {
      if (!mounted) return;
      _handleAiError(e.toString());
    }
    _scrollToBottom();
  }

  // Real Gemini API message sending function
  Future<void> send() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": text, "isAttachment": false});
      isLoading = true;
    });
    controller.clear();
    _scrollToBottom();

    // Check if Chat Session is initialized
    if (_chatSession == null) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        isLoading = false;
        messages.add({
          "role": "ai", 
          "text": "⚠️ System Error!\n\nAI Model failed to initialize. Please check your flutter package version and API key.",
          "isAttachment": false,
        });
      });
      _scrollToBottom();
      return;
    }

    // Pure AI Chat processing
    try {
      String apiPayload = text;
      if (_isFirstMessage && widget.healthData != null) {
        apiPayload = "USER PROMPT: $text";
        _isFirstMessage = false;
      }

      final response = await _chatSession!.sendMessage(Content.text(apiPayload));

      if (!mounted) return;
      setState(() {
        messages.add({"role": "ai", "text": response.text ?? "I couldn't process that.", "isAttachment": false});
      });
    } catch (e) {
      if (!mounted) return;
      _handleAiError(e.toString());
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
      _scrollToBottom();
    }
  }

  // Smart Error Handler function
  void _handleAiError(String errorMsg) {
    String friendlyMessage = "Error: Real AI communication failed. \nDetails: $errorMsg";

    if (errorMsg.contains("not found") || errorMsg.contains("404")) {
      friendlyMessage = "⚠️ Server Update Pending\n\nAapne API key abhi just banayi hai! Google ke server par nayi key ko activate hone me 5 se 10 minute lagte hain. Kripya thoda wait karke wapas try karein. ⏳";
    } else if (errorMsg.contains("API version")) {
      friendlyMessage = "⚠️ Package Update Required\n\nAapka 'google_generative_ai' package purana ho gaya hai. Terminal mein 'flutter pub upgrade' run karein aur app ko restart karein.";
    }

    setState(() {
      isLoading = false;
      messages.add({
        "role": "ai", 
        "text": friendlyMessage,
        "isAttachment": false
      });
    });
  }

  // Scroll to latest message
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDarkMode;
    final Color bgColor = isDark ? const Color(0xFF0F1115) : const Color(0xFFF4F7FA);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E2029);
    final Color inputBgColor = isDark ? const Color(0xFF1A1D24) : Colors.white;
    final Color aiBubbleColor = isDark ? const Color(0xFF1A1D24) : Colors.white;
    final Color aiTextColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Premium Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AI Diet Assistant",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: (_chatSession != null) ? Colors.greenAccent : Colors.orangeAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            (_chatSession != null) ? "Gemini AI Active" : "Initializing...",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Chat Area
            Expanded(
              child: Container(
                color: bgColor,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      // Loading Indicator Premium
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: aiBubbleColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF)),
                              ),
                              const SizedBox(width: 12),
                              Text("Gemini is thinking...", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    }

                    final msg = messages[index];
                    final isUser = msg['role'] == 'user';
                    final isAttachment = msg['isAttachment'] == true;

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.85,
                        ),
                        decoration: BoxDecoration(
                          gradient: isUser && !isAttachment
                              ? const LinearGradient(
                                  colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isAttachment 
                              ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200) 
                              : (isUser ? null : aiBubbleColor),
                          border: isUser && !isAttachment ? null : Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
                            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isUser && !isAttachment ? const Color(0xFF6C63FF).withOpacity(0.3) : Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SelectableText( 
                          msg['text']!,
                          style: TextStyle(
                            color: isAttachment 
                                ? (isDark ? Colors.white70 : Colors.black54)
                                : (isUser ? Colors.white : aiTextColor),
                            fontSize: 15,
                            height: 1.5,
                            fontWeight: isUser && !isAttachment ? FontWeight.w500 : FontWeight.w400,
                            fontStyle: isAttachment ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 3. Premium Input Area with Attachment Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: inputBgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Attachment Button
                  GestureDetector(
                    onTap: _attachReport,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F1115) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                      ),
                      child: Icon(Icons.attach_file_rounded, color: isDark ? Colors.white70 : Colors.grey.shade700, size: 22),
                    ),
                  ),
                  const SizedBox(width: 10),
                  
                  // Text Field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F1115) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                      ),
                      child: TextField(
                        controller: controller,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: "Type your preference...",
                          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          isDense: true,
                        ),
                        minLines: 1,
                        maxLines: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  
                  // Glowing Send Button
                  GestureDetector(
                    onTap: send,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))
                        ],
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}