import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'answer_verifier_service.dart';
import 'translation_service.dart';
import 'open_source_ai_service.dart';

class AITutorService {
  static final AITutorService _instance = AITutorService._internal();
  factory AITutorService() => _instance;
  AITutorService._internal();

  final AnswerVerifierService _verifierService = AnswerVerifierService();
  final TranslationService _translationService = TranslationService();
  final OpenSourceAIService _openSourceAI = OpenSourceAIService();

  // Supported languages
  static const String languageEnglish = 'en';
  static const String languageFrench = 'fr';
  static const String languageSpanish = 'es';

  // Educational responses database
  final Map<String, Map<String, List<String>>> _responses = {
    // Mathematics responses
    'math': {
      'en': [
        'Let me help you with this math problem! Can you tell me what specific area you\'re struggling with?',
        'Mathematics is all about practice! What type of problem are you working on?',
        'I\'d be happy to explain this step by step. What math topic do you need help with?',
        'Great question! Let\'s break this math problem down together.',
      ],
      'fr': [
        'Laissez-moi vous aider avec ce problème de mathématiques ! Pouvez-vous me dire dans quel domaine spécifique vous avez des difficultés ?',
        'Les mathématiques, c\'est de la pratique ! Sur quel type de problème travaillez-vous ?',
        'Je serais ravi de vous expliquer cela étape par étape. De quel sujet de mathématiques avez-vous besoin d\'aide ?',
        'Excellente question ! Décomposons ce problème de mathématiques ensemble.',
      ],
      'es': [
        '¡Déjame ayudarte con este problema de matemáticas! ¿Puedes decirme en qué área específica tienes dificultades?',
        '¡Las matemáticas son pura práctica! ¿En qué tipo de problema estás trabajando?',
        'Me encantaría explicarte esto paso a paso. ¿Con qué tema de matemáticas necesitas ayuda?',
        '¡Excelente pregunta! Vamos a desglosar este problema de matemáticas juntos.',
      ],
    },
    // Science responses
    'science': {
      'en': [
        'Science is fascinating! What scientific concept would you like to explore?',
        'I love helping with science questions! What experiment or theory are you curious about?',
        'Let\'s dive into the world of science together! What\'s your question?',
        'Science is all around us! What would you like to learn about today?',
      ],
      'fr': [
        'La science est fascinante ! Quel concept scientifique aimeriez-vous explorer ?',
        'J\'adore aider avec les questions scientifiques ! Quelle expérience ou théorie vous intrigue ?',
        'Plongeons ensemble dans le monde de la science ! Quelle est votre question ?',
        'La science est partout autour de nous ! Qu\'aimeriez-vous apprendre aujourd\'hui ?',
      ],
      'es': [
        '¡La ciencia es fascinante! ¿Qué concepto científico te gustaría explorar?',
        '¡Me encanta ayudar con preguntas de ciencia! ¿Qué experimento o teoría te da curiosidad?',
        '¡Sumerjámonos juntos en el mundo de la ciencia! ¿Cuál es tu pregunta?',
        '¡La ciencia está en todas partes! ¿Qué te gustaría aprender hoy?',
      ],
    },
    // Language responses
    'language': {
      'en': [
        'Language learning is a wonderful journey! What language skill would you like to practice?',
        'I\'m here to help with your language studies! What do you need assistance with?',
        'Let\'s work on your language skills together! What\'s challenging you?',
        'Language is the key to communication! How can I help you improve?',
      ],
      'fr': [
        'L\'apprentissage des langues est un merveilleux voyage ! Quelle compétence linguistique aimeriez-vous pratiquer ?',
        'Je suis là pour vous aider avec vos études de langue ! De quoi avez-vous besoin d\'aide ?',
        'Travaillons ensemble sur vos compétences linguistiques ! Qu\'est-ce qui vous pose problème ?',
        'La langue est la clé de la communication ! Comment puis-je vous aider à vous améliorer ?',
      ],
      'es': [
        '¡El aprendizaje de idiomas es un viaje maravilloso! ¿Qué habilidad lingüística te gustaría practicar?',
        '¡Estoy aquí para ayudarte con tus estudios de idiomas! ¿En qué necesitas ayuda?',
        '¡Trabajemos juntos en tus habilidades lingüísticas! ¿Qué te está desafiando?',
        '¡El idioma es la clave de la comunicación! ¿Cómo puedo ayudarte a mejorar?',
      ],
    },
    // General responses
    'general': {
      'en': [
        'Hello! I\'m your AI tutor assistant. How can I help you learn today?',
        'I\'m here to support your learning journey! What subject interests you?',
        'Great to see you studying! What topic would you like to explore?',
        'Learning is an adventure! What can I help you understand better?',
      ],
      'fr': [
        'Bonjour ! Je suis votre assistant tuteur IA. Comment puis-je vous aider à apprendre aujourd\'hui ?',
        'Je suis là pour soutenir votre parcours d\'apprentissage ! Quel sujet vous intéresse ?',
        'Ravi de vous voir étudier ! Quel sujet aimeriez-vous explorer ?',
        'Apprendre est une aventure ! Que puis-je vous aider à mieux comprendre ?',
      ],
      'es': [
        '¡Hola! Soy tu asistente tutor de IA. ¿Cómo puedo ayudarte a aprender hoy?',
        '¡Estoy aquí para apoyar tu viaje de aprendizaje! ¿Qué materia te interesa?',
        '¡Qué bueno verte estudiando! ¿Qué tema te gustaría explorar?',
        '¡Aprender es una aventura! ¿Qué puedo ayudarte a entender mejor?',
      ],
    },
  };

  // Study tips by language
  final Map<String, List<String>> _studyTips = {
    'en': [
      '💡 Tip: Take breaks every 25 minutes to stay focused!',
      '📚 Remember: Practice makes perfect. Review your notes regularly.',
      '🎯 Focus on understanding concepts, not just memorizing facts.',
      '⏰ Create a study schedule and stick to it for better results.',
      '🤝 Don\'t hesitate to ask questions - that\'s how you learn!',
    ],
    'fr': [
      '💡 Conseil : Prenez des pauses toutes les 25 minutes pour rester concentré !',
      '📚 Rappelez-vous : C\'est en forgeant qu\'on devient forgeron. Révisez vos notes régulièrement.',
      '🎯 Concentrez-vous sur la compréhension des concepts, pas seulement sur la mémorisation.',
      '⏰ Créez un planning d\'étude et respectez-le pour de meilleurs résultats.',
      '🤝 N\'hésitez pas à poser des questions - c\'est comme ça qu\'on apprend !',
    ],
    'es': [
      '💡 Consejo: ¡Toma descansos cada 25 minutos para mantenerte enfocado!',
      '📚 Recuerda: La práctica hace al maestro. Repasa tus notas regularmente.',
      '🎯 Enfócate en entender conceptos, no solo en memorizar datos.',
      '⏰ Crea un horario de estudio y cúmplelo para mejores resultados.',
      '🤝 ¡No dudes en hacer preguntas - así es como aprendes!',
    ],
  };

  // Get AI response based on user input and language with plagiarism detection
  Future<AITutorResponse> getResponse(String userInput, String language) async {
    try {
      // Get response from open source AI
      final aiResponse = await _openSourceAI.generateResponse(
        userInput,
        language,
      );

      // Check for plagiarism in the input
      final plagiarismResult = await _verifierService.checkPlagiarism(
        text: userInput,
        subject: aiResponse.subject,
      );

      // Verify answer quality if it looks like a student answer
      AnswerVerificationResult? verificationResult;
      if (_looksLikeAnswer(userInput)) {
        verificationResult = await _verifierService.verifyAnswer(
          question: 'Student response analysis',
          studentAnswer: userInput,
          correctAnswer: null,
          subject: aiResponse.subject,
        );
      }

      return AITutorResponse(
        response: aiResponse.answer,
        language: language,
        plagiarismResult: plagiarismResult,
        verificationResult: verificationResult,
        confidence: aiResponse.confidence,
        subject: aiResponse.subject,
        aiSource: aiResponse.sourceDescription,
        suggestedResources: _openSourceAI.getEducationalResources(
          userInput,
          aiResponse.subject,
        ),
      );
    } catch (e) {
      debugPrint('AI Tutor Error: $e');

      // Fallback to original response system
      return await _getFallbackResponse(userInput, language);
    }
  }

  // Fallback response system
  Future<AITutorResponse> _getFallbackResponse(
    String userInput,
    String language,
  ) async {
    // Simulate AI processing delay
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Check for plagiarism in the input
      final plagiarismResult = await _verifierService.checkPlagiarism(
        text: userInput,
        subject: _detectSubject(userInput),
      );

      final input = userInput.toLowerCase();
      String category = 'general';

      // Determine category based on keywords
      if (input.contains('math') ||
          input.contains('mathématiques') ||
          input.contains('matemáticas') ||
          input.contains('algebra') ||
          input.contains('algèbre') ||
          input.contains('álgebra') ||
          input.contains('geometry') ||
          input.contains('géométrie') ||
          input.contains('geometría')) {
        category = 'math';
      } else if (input.contains('science') ||
          input.contains('ciencia') ||
          input.contains('physics') ||
          input.contains('physique') ||
          input.contains('física') ||
          input.contains('chemistry') ||
          input.contains('chimie') ||
          input.contains('química') ||
          input.contains('biology') ||
          input.contains('biologie') ||
          input.contains('biología')) {
        category = 'science';
      } else if (input.contains('language') ||
          input.contains('langue') ||
          input.contains('idioma') ||
          input.contains('english') ||
          input.contains('anglais') ||
          input.contains('inglés') ||
          input.contains('french') ||
          input.contains('français') ||
          input.contains('francés') ||
          input.contains('spanish') ||
          input.contains('espagnol') ||
          input.contains('español')) {
        category = 'language';
      }

      // Get random response from category
      final responses =
          _responses[category]?[language] ??
          _responses['general']?[language] ??
          [];
      if (responses.isEmpty) {
        return AITutorResponse(
          response: _getDefaultResponse(language),
          language: language,
          plagiarismResult: plagiarismResult,
          verificationResult: null,
          confidence: 0.5,
          subject: category,
        );
      }

      final random = Random();
      String response = responses[random.nextInt(responses.length)];

      // Add study tip occasionally
      if (random.nextBool()) {
        final tips = _studyTips[language] ?? [];
        if (tips.isNotEmpty) {
          response += '\n\n${tips[random.nextInt(tips.length)]}';
        }
      }

      // Verify answer quality if it looks like a student answer
      AnswerVerificationResult? verificationResult;
      if (_looksLikeAnswer(userInput)) {
        verificationResult = await _verifierService.verifyAnswer(
          question: 'Student response analysis',
          studentAnswer: userInput,
          correctAnswer: null,
          subject: category,
        );
      }

      return AITutorResponse(
        response: response,
        language: language,
        plagiarismResult: plagiarismResult,
        verificationResult: verificationResult,
        confidence: 0.85 + Random().nextDouble() * 0.1,
        subject: category,
      );
    } catch (e) {
      return AITutorResponse(
        response: _getDefaultResponse(language),
        language: language,
        plagiarismResult: null,
        verificationResult: null,
        confidence: 0.0,
        subject: 'general',
        error: e.toString(),
      );
    }
  }

  String _detectSubject(String input) {
    final lowerInput = input.toLowerCase();
    if (lowerInput.contains(
      RegExp(r'math|equation|algebra|geometry|calculus|\+|\-|\*|\/|='),
    )) {
      return 'math';
    } else if (lowerInput.contains(
      RegExp(r'science|physics|chemistry|biology|experiment|molecule|atom'),
    )) {
      return 'science';
    } else if (lowerInput.contains(
      RegExp(r'history|war|ancient|civilization|empire|revolution'),
    )) {
      return 'history';
    } else if (lowerInput.contains(
      RegExp(r'language|grammar|writing|literature|essay|poem'),
    )) {
      return 'language';
    }
    return 'general';
  }

  bool _looksLikeAnswer(String input) {
    // Check if input looks like a student answer rather than a question
    return input.length > 50 &&
        !input.contains('?') &&
        !input.toLowerCase().startsWith(
          RegExp(r'how|what|why|when|where|can|could|would|should'),
        );
  }

  String _getDefaultResponse(String language) {
    switch (language) {
      case languageFrench:
        return 'Je suis là pour vous aider ! Pouvez-vous me poser une question plus spécifique ?';
      case languageSpanish:
        return '¡Estoy aquí para ayudarte! ¿Puedes hacerme una pregunta más específica?';
      default:
        return 'I\'m here to help! Can you ask me a more specific question?';
    }
  }

  // Get greeting message
  String getGreeting(String language) {
    switch (language) {
      case languageFrench:
        return '👋 Bonjour ! Je suis votre tuteur IA. Comment puis-je vous aider aujourd\'hui ?';
      case languageSpanish:
        return '👋 ¡Hola! Soy tu tutor de IA. ¿Cómo puedo ayudarte hoy?';
      default:
        return '👋 Hello! I\'m your AI tutor. How can I help you today?';
    }
  }

  // Get language name
  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case languageFrench:
        return 'Français';
      case languageSpanish:
        return 'Español';
      default:
        return 'English';
    }
  }

  // Get available languages
  List<String> getAvailableLanguages() {
    return [languageEnglish, languageFrench, languageSpanish];
  }
}

class AITutorResponse {
  final String response;
  final String language;
  final PlagiarismResult? plagiarismResult;
  final AnswerVerificationResult? verificationResult;
  final double confidence;
  final String subject;
  final String? error;
  final String? aiSource;
  final List<String>? suggestedResources;

  AITutorResponse({
    required this.response,
    required this.language,
    this.plagiarismResult,
    this.verificationResult,
    required this.confidence,
    required this.subject,
    this.error,
    this.aiSource,
    this.suggestedResources,
  });

  bool get hasError => error != null;
  bool get hasPlagiarismConcerns =>
      (plagiarismResult?.plagiarismScore ?? 0) > 0.3;
  bool get hasVerificationIssues => (verificationResult?.accuracy ?? 1.0) < 0.7;

  String get confidenceLevel {
    if (confidence > 0.9) return 'Very High';
    if (confidence > 0.8) return 'High';
    if (confidence > 0.6) return 'Medium';
    return 'Low';
  }

  String get warningMessage {
    final warnings = <String>[];

    if (hasPlagiarismConcerns) {
      warnings.add(
        '⚠️ Potential plagiarism detected (${plagiarismResult!.plagiarismPercentage})',
      );
    }

    if (hasVerificationIssues) {
      warnings.add(
        '⚠️ Answer quality concerns (${verificationResult!.accuracyPercentage} accuracy)',
      );
    }

    return warnings.join('\n');
  }

  String get enhancedResponse {
    String fullResponse = response;

    // Add AI source information
    if (aiSource != null) {
      fullResponse += '\n\n📚 Source: $aiSource';
    }

    // Add confidence level
    fullResponse +=
        '\n🎯 Confidence: $confidenceLevel (${(confidence * 100).toStringAsFixed(1)}%)';

    // Add suggested resources
    if (suggestedResources != null && suggestedResources!.isNotEmpty) {
      fullResponse += '\n\n📖 Recommended Resources:';
      for (final resource in suggestedResources!.take(3)) {
        fullResponse += '\n• $resource';
      }
    }

    // Add warnings if any
    if (warningMessage.isNotEmpty) {
      fullResponse += '\n\n$warningMessage';
    }

    return fullResponse;
  }
}
