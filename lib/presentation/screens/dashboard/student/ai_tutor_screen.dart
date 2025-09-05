import 'package:flutter/material.dart';
import '../../../../core/services/ai_tutor_service.dart';
import '../../../../core/services/voice_input_service.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/services/answer_verifier_service.dart';
import '../../../../data/models/user_model.dart';

class AITutorScreen extends StatefulWidget {
  final UserModel user;

  const AITutorScreen({super.key, required this.user});

  @override
  State<AITutorScreen> createState() => _AITutorScreenState();
}

class _AITutorScreenState extends State<AITutorScreen> {
  final AITutorService _aiTutorService = AITutorService();
  final VoiceInputService _voiceService = VoiceInputService();
  final TranslationService _translationService = TranslationService();
  final AnswerVerifierService _verifierService = AnswerVerifierService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _selectedLanguage = AITutorService.languageEnglish;
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _addWelcomeMessage();
  }

  Future<void> _initializeServices() async {
    await _voiceService.initialize();
    _voiceService.speechStream.listen((text) {
      if (text.isNotEmpty) {
        _messageController.text = text;
      }
    });
    _voiceService.listeningStream.listen((isListening) {
      setState(() {
        _isListening = isListening;
      });
    });
  }

  void _addWelcomeMessage() {
    final greeting = _aiTutorService.getGreeting(_selectedLanguage);
    setState(() {
      _messages.add(
        ChatMessage(text: greeting, isUser: false, timestamp: DateTime.now()),
      );
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(
        ChatMessage(text: userMessage, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await _aiTutorService.getResponse(
        userMessage,
        _selectedLanguage,
      );

      // Use enhanced response with AI source, confidence, and resources
      String responseText = response.enhancedResponse;

      setState(() {
        _messages.add(
          ChatMessage(
            text: responseText,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: _getErrorMessage(),
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  String _getErrorMessage() {
    switch (_selectedLanguage) {
      case AITutorService.languageFrench:
        return 'Désolé, j\'ai rencontré un problème. Pouvez-vous réessayer ?';
      case AITutorService.languageSpanish:
        return 'Lo siento, tuve un problema. ¿Puedes intentar de nuevo?';
      default:
        return 'Sorry, I encountered an issue. Can you try again?';
    }
  }

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

  void _changeLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
      _messages.clear();
    });
    _addWelcomeMessage();
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _voiceService.stopListening();
    } else {
      final languageCode = _getVoiceLanguageCode(_selectedLanguage);
      await _voiceService.startListening(language: languageCode);
    }
  }

  String _getVoiceLanguageCode(String language) {
    switch (language) {
      case AITutorService.languageFrench:
        return 'fr-FR';
      case AITutorService.languageSpanish:
        return 'es-ES';
      default:
        return 'en-US';
    }
  }

  Future<void> _translateMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final result = await _translationService.translateText(
        text: _messageController.text.trim(),
        fromLanguage: 'auto',
        toLanguage: _selectedLanguage,
      );

      if (result.isSuccessful) {
        _messageController.text = result.translatedText;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Translation failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 AI Tutor Assistant'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: _changeLanguage,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: AITutorService.languageEnglish,
                child: Row(
                  children: [
                    const Text('🇺🇸'),
                    const SizedBox(width: 8),
                    Text(
                      _aiTutorService.getLanguageName(
                        AITutorService.languageEnglish,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: AITutorService.languageFrench,
                child: Row(
                  children: [
                    const Text('🇫🇷'),
                    const SizedBox(width: 8),
                    Text(
                      _aiTutorService.getLanguageName(
                        AITutorService.languageFrench,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: AITutorService.languageSpanish,
                child: Row(
                  children: [
                    const Text('🇪🇸'),
                    const SizedBox(width: 8),
                    Text(
                      _aiTutorService.getLanguageName(
                        AITutorService.languageSpanish,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Language indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.blue.shade50,
            child: Text(
              'Language: ${_aiTutorService.getLanguageName(_selectedLanguage)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }

                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Voice input button
                FloatingActionButton(
                  onPressed: _toggleVoiceInput,
                  mini: true,
                  backgroundColor: _isListening ? Colors.red : Colors.green,
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _getInputHint(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: _messageController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.translate),
                              onPressed: _translateMessage,
                            )
                          : null,
                    ),
                    maxLines: null,
                    onSubmitted: (_) => _sendMessage(),
                    onChanged: (text) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  mini: true,
                  backgroundColor: Colors.blue.shade600,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInputHint() {
    switch (_selectedLanguage) {
      case AITutorService.languageFrench:
        return 'Posez votre question...';
      case AITutorService.languageSpanish:
        return 'Haz tu pregunta...';
      default:
        return 'Ask your question...';
    }
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blue.shade600 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: message.isUser ? Colors.white70 : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('AI is typing'),
            const SizedBox(width: 8),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
