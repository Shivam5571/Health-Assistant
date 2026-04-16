import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Note: Asli app mein in packages ko pubspec.yaml mein add karke uncomment karein:
// import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:google_generative_ai/google_generative_ai.dart';

// --- MESSAGE MODEL ---
class ChatMessage {
  final String text;
  final bool isUser;
  final String? attachmentPath; // Image ya PDF ka path
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.attachmentPath,
    required this.timestamp,
  });
}

class AIAssistantScreen extends StatefulWidget {
  final bool isDarkMode; // Theme detect karne ke liye
  
  const AIAssistantScreen({super.key, this.isDarkMode = false});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String userName = "User";
  String userContext = ""; // User ki profile history (Age, Weight, Medical etc.)

  @override
  void initState() {
    super.initState();
    _fetchUserDataAndGreet();
  }

  // User ka data fetch karke friendly greeting generate karna
  void _fetchUserDataAndGreet() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.displayName != null) {
      userName = user.displayName!.split(' ')[0];
    }

    // Dummy context, asli app mein ye Firestore profile se aayega
    userContext = "User ki age 25 hai, weight 70kg hai. Fitness enthusiast hain.";

    // Pehla greeting message
    setState(() {
      _messages.add(
        ChatMessage(
          text: "Hello $userName! 👋 Main aapki AI Health Assistant hoon. Aaj main aapki diet, fitness ya medical reports samajhne mein kaise madad kar sakti hoon? 😊",
          isUser: false,
          timestamp: DateTime.now(),
        )
      );
    });
  }

  // --- MESSAGE SEND KARNE KA LOGIC ---
  Future<void> _sendMessage({String? attachment}) async {
    final text = _msgController.text.trim();
    if (text.isEmpty && attachment == null) return;

    _msgController.clear();
    
    // User ka message UI mein add karein
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        attachmentPath: attachment,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    // AI ka response lana (Simulated API Call)
    await _getAIResponse(text, attachmentPath: attachment);
  }

  // --- GEMINI AI INTEGRATION (MOCK) ---
  Future<void> _getAIResponse(String userText, {String? attachmentPath}) async {
    /* // === ASLI GEMINI API LOGIC YAHAN LAGEGA ===
    // 1. Pubspec mein daalein: google_generative_ai
    // 2. Setup karein:
    final apiKey = 'YOUR_GEMINI_API_KEY';
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey); // Flash multimodal support karta hai
    
    // System instruction (Chatbot ki personality aur user context)
    String prompt = "Tum ek friendly aur expert health assistant ho. User ka naam $userName hai. Context: $userContext. User ka sawal: $userText";
    
    try {
      GenerateContentResponse response;
      if (attachmentPath != null) {
        // Agar file hai toh usko bytes mein convert karke bhejein
        final bytes = await File(attachmentPath).readAsBytes();
        final imagePart = DataPart('image/jpeg', bytes); // Ya pdf ke liye application/pdf
        response = await model.generateContent([
          Content.multi([TextPart(prompt), imagePart])
        ]);
      } else {
        response = await model.generateContent([Content.text(prompt)]);
      }
      
      final aiText = response.text ?? "Maaf karna, mujhe samajh nahi aaya.";
      // Message add karein ...
    } catch (e) {
      // Error handling
    }
    */

    // Simulated network delay (API call ki acting)
    await Future.delayed(const Duration(seconds: 2));

    String aiReply = "";
    if (attachmentPath != null) {
      aiReply = "$userName, maine aapki report/photo analyze kar li hai. Sab kuch normal lag raha hai, par please doctor se ek baar confirm kar lein. Kuch aur janna hai iske baare mein?";
    } else {
      aiReply = "Bilkul $userName! Main aapki madad zaroor karungi. Aap mujhe apni daily routine ke baare mein thoda aur batayein taaki main ek perfect plan bana saku.";
    }

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: aiReply,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    }
  }

  // --- FILE ATTACHMENT LOGIC ---
  Future<void> _showAttachmentOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.isDarkMode ? const Color(0xFF1A1D24) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("File Attach Karein", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachOption(Icons.camera_alt_rounded, "Camera", Colors.blueAccent, () {
                  Navigator.pop(context);
                  // Use ImagePicker().pickImage(source: ImageSource.camera)
                  _sendMessage(attachment: "mock_camera_path.jpg");
                }),
                _buildAttachOption(Icons.image_rounded, "Gallery", Colors.purpleAccent, () {
                  Navigator.pop(context);
                  // Use ImagePicker().pickImage(source: ImageSource.gallery)
                  _sendMessage(attachment: "mock_gallery_path.jpg");
                }),
                _buildAttachOption(Icons.picture_as_pdf_rounded, "Document", Colors.redAccent, () {
                  Navigator.pop(context);
                  // Use FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'])
                  _sendMessage(attachment: "mock_report.pdf");
                }),
              ],
            )
          ],
        ),
      )
    );
  }

  Widget _buildAttachOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // --- HISTORY DIALOG ---
  void _openChatHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1A1D24) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Purani Chats", style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.history_rounded, color: Colors.blueAccent),
                title: Text("Diet Plan for Weight Loss", style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
                subtitle: const Text("Kal"),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.history_rounded, color: Colors.blueAccent),
                title: Text("Blood Test Report Analysis", style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
                subtitle: const Text("Pichle hafte"),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      )
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? const Color(0xFF0F1115) : const Color(0xFFF4F7FA);
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF1E2029);
    final cardColor = widget.isDarkMode ? const Color(0xFF1A1D24) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF6C63FF), size: 18),
            ),
            const SizedBox(width: 10),
            Text("AI Health Assistant", style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: textColor),
            onPressed: _openChatHistory,
            tooltip: "Chat History",
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildChatBubble(msg, cardColor, textColor);
              },
            ),
          ),
          
          // Typing Indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF)),
                      ),
                      const SizedBox(width: 8),
                      Text("AI soch rahi hai...", style: TextStyle(color: widget.isDarkMode ? Colors.white60 : Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom Input Area (Frosted Glass Effect)
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 12, top: 12, left: 16, right: 16),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.8),
                  border: Border(top: BorderSide(color: widget.isDarkMode ? Colors.white10 : Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    // Attachment Button
                    Container(
                      decoration: BoxDecoration(
                        color: widget.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.add_rounded, color: textColor),
                        onPressed: _showAttachmentOptions,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Text Input Field
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode ? Colors.black26 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.transparent),
                        ),
                        child: TextField(
                          controller: _msgController,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: "Apna sawal puchein ya report bhejein...",
                            hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white30 : Colors.grey),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Send Button
                    GestureDetector(
                      onTap: () => _sendMessage(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF9D4EDD)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- MESSAGE BUBBLE UI ---
  Widget _buildChatBubble(ChatMessage msg, Color cardColor, Color textColor) {
    bool isMe = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFF6C63FF).withOpacity(0.5), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFF6C63FF),
                child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
              ),
            ),
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF6C63FF) : cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Agar koi file attach ki hai user ne
                  if (msg.attachmentPath != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            msg.attachmentPath!.endsWith(".pdf") ? Icons.picture_as_pdf_rounded : Icons.image_rounded, 
                            color: isMe ? Colors.white : textColor, 
                            size: 20
                          ),
                          const SizedBox(width: 8),
                          Text("File Attached", style: TextStyle(color: isMe ? Colors.white : textColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  
                  // Main text message
                  if (msg.text.isNotEmpty)
                    Text(
                      msg.text,
                      style: TextStyle(
                        color: isMe ? Colors.white : textColor,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          if (isMe) const SizedBox(width: 20), // Placeholder to balance AI avatar space
        ],
      ),
    );
  }
}