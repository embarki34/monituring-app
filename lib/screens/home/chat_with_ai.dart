import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  final String apiKey;

  ChatScreen({required this.apiKey});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _storage = FlutterSecureStorage();
  late GenerativeModel model;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  late ChatSession chatSession;
  bool _isFirstMessage = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    final safetySettings = [
      SafetySetting(HarmCategory.harassment, HarmBlockThreshold.unspecified),
      SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.unspecified),
      SafetySetting(
          HarmCategory.sexuallyExplicit, HarmBlockThreshold.unspecified),
      SafetySetting(
          HarmCategory.dangerousContent, HarmBlockThreshold.unspecified),
    ];

    model = GenerativeModel(
      model: 'gemini-1.0-pro',
      apiKey: widget.apiKey,
      safetySettings: safetySettings,
    );

    _initializeChat();
  }

  void _initializeChat() async {
    setState(() {
      _isLoading = true;
    });

    final masterPrompt =
        "من فضلك، تحدث إليّ باللغة العربية. أنا مريض بالسرطان وأحتاج إلى شخص للاستماع إليّ ومساعدتي في تخفيف مشاعري. أريدك أن تكون لطيفًا ومتفهمًا.";

    final history = [Content.text(masterPrompt)];

    chatSession = await model.startChat(history: history);

    final initialResponse = await _sendMessageToAI(masterPrompt);

    setState(() {
      _messages.add({'role': 'ai', 'content': initialResponse});
      _isLoading = false;
    });

    _scrollToBottom();
  }

  Future<String> _sendMessageToAI(String message) async {
    try {
      final typingMessage = {
        'role': 'ai',
        'content': 'الذكاء الاصطناعي يكتب...'
      };
      setState(() {
        _messages.add(typingMessage);
      });
      _scrollToBottom();

      final response = await chatSession.sendMessage(Content.text(message));

      setState(() {
        _messages.remove(typingMessage);
      });

      return response.text ?? 'لا توجد استجابة';
    } catch (e) {
      setState(() {
        _messages
            .removeWhere((msg) => msg['content'] == 'الذكاء الاصطناعي يكتب...');
      });
      print('Error: $e');
      return 'خطأ: غير قادر على معالجة طلبك.';
    }
  }

  Future<void> _sendChatToEndpoint(String message) async {
    final token = await _storage.read(key: 'token');
    final response = await http.post(
      Uri.parse(
          'https://honeybee-prime-supposedly.ngrok-free.app/analyze_chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'chat_data': message}),
    );
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    final userMessage = _controller.text;

    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _isLoading = true;
      if (_isFirstMessage) _isFirstMessage = false;
    });

    final aiResponse = await _sendMessageToAI(userMessage);
    await _sendChatToEndpoint(userMessage); // Send the message to the backend

    setState(() {
      _messages.add({'role': 'ai', 'content': aiResponse});
      _isLoading = false;
    });

    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Allow resizing
      appBar: AppBar(
        title: Text('الدردشة مع المساعد'),
        backgroundColor: Color.fromARGB(255, 229, 236, 239),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    ..._messages.map((message) {
                      final isUserMessage = message['role'] == 'user';
                      return Align(
                        alignment: isUserMessage
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          padding: EdgeInsets.all(12),
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isUserMessage
                                ? const Color.fromARGB(255, 83, 176, 255)
                                : Color.fromARGB(255, 230, 230, 230),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isUserMessage
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(
                                message['content']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              if (isUserMessage) SizedBox(height: 4),
                              if (isUserMessage)
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: CircleAvatar(
                                    backgroundColor:
                                        Color.fromARGB(255, 83, 176, 255),
                                    child: Text('أنا'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالتك . . .',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        filled: true,
                        fillColor: Color.fromARGB(255, 240, 240, 240),
                        hintStyle: TextStyle(color: Colors.black54),
                      ),
                      style: TextStyle(color: Colors.black87),
                      textAlign: TextAlign.right,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      onTap: () {
                        _focusNode.requestFocus(); // Keep the keyboard open
                      },
                      onSubmitted: (_) =>
                          _sendMessage(), // Send message on return
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send,
                        color: Color.fromARGB(255, 83, 176, 255)),
                    onPressed: _sendMessage,
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
