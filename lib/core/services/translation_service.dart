import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  // Supported languages with their codes and names
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'zh': 'Chinese',
    'ja': 'Japanese',
    'ko': 'Korean',
    'ar': 'Arabic',
    'hi': 'Hindi',
    'tr': 'Turkish',
    'pl': 'Polish',
    'nl': 'Dutch',
  };

  // Common educational translations database
  final Map<String, Map<String, String>> _translations = {
    // Math terms
    'equation': {
      'en': 'equation',
      'es': 'ecuación',
      'fr': 'équation',
      'de': 'Gleichung',
      'it': 'equazione',
      'pt': 'equação',
    },
    'solve': {
      'en': 'solve',
      'es': 'resolver',
      'fr': 'résoudre',
      'de': 'lösen',
      'it': 'risolvere',
      'pt': 'resolver',
    },
    'mathematics': {
      'en': 'mathematics',
      'es': 'matemáticas',
      'fr': 'mathématiques',
      'de': 'Mathematik',
      'it': 'matematica',
      'pt': 'matemática',
    },
    // Science terms
    'science': {
      'en': 'science',
      'es': 'ciencia',
      'fr': 'science',
      'de': 'Wissenschaft',
      'it': 'scienza',
      'pt': 'ciência',
    },
    'experiment': {
      'en': 'experiment',
      'es': 'experimento',
      'fr': 'expérience',
      'de': 'Experiment',
      'it': 'esperimento',
      'pt': 'experimento',
    },
    'photosynthesis': {
      'en': 'photosynthesis',
      'es': 'fotosíntesis',
      'fr': 'photosynthèse',
      'de': 'Photosynthese',
      'it': 'fotosintesi',
      'pt': 'fotossíntese',
    },
    // Common phrases
    'hello': {
      'en': 'Hello',
      'es': 'Hola',
      'fr': 'Bonjour',
      'de': 'Hallo',
      'it': 'Ciao',
      'pt': 'Olá',
    },
    'help': {
      'en': 'help',
      'es': 'ayuda',
      'fr': 'aide',
      'de': 'Hilfe',
      'it': 'aiuto',
      'pt': 'ajuda',
    },
    'question': {
      'en': 'question',
      'es': 'pregunta',
      'fr': 'question',
      'de': 'Frage',
      'it': 'domanda',
      'pt': 'pergunta',
    },
    'answer': {
      'en': 'answer',
      'es': 'respuesta',
      'fr': 'réponse',
      'de': 'Antwort',
      'it': 'risposta',
      'pt': 'resposta',
    },
    'homework': {
      'en': 'homework',
      'es': 'tarea',
      'fr': 'devoirs',
      'de': 'Hausaufgaben',
      'it': 'compiti',
      'pt': 'lição de casa',
    },
    'study': {
      'en': 'study',
      'es': 'estudiar',
      'fr': 'étudier',
      'de': 'studieren',
      'it': 'studiare',
      'pt': 'estudar',
    },
    'learn': {
      'en': 'learn',
      'es': 'aprender',
      'fr': 'apprendre',
      'de': 'lernen',
      'it': 'imparare',
      'pt': 'aprender',
    },
    'teacher': {
      'en': 'teacher',
      'es': 'profesor',
      'fr': 'professeur',
      'de': 'Lehrer',
      'it': 'insegnante',
      'pt': 'professor',
    },
    'student': {
      'en': 'student',
      'es': 'estudiante',
      'fr': 'étudiant',
      'de': 'Student',
      'it': 'studente',
      'pt': 'estudante',
    },
  };

  // Translate text from one language to another
  Future<TranslationResult> translateText({
    required String text,
    required String fromLanguage,
    required String toLanguage,
  }) async {
    try {
      // Simulate translation processing time
      await Future.delayed(const Duration(milliseconds: 500));

      if (fromLanguage == toLanguage) {
        return TranslationResult(
          originalText: text,
          translatedText: text,
          fromLanguage: fromLanguage,
          toLanguage: toLanguage,
          confidence: 1.0,
          isSuccessful: true,
        );
      }

      // Try to find exact matches in our translation database
      final lowerText = text.toLowerCase().trim();
      if (_translations.containsKey(lowerText)) {
        final translations = _translations[lowerText]!;
        if (translations.containsKey(toLanguage)) {
          return TranslationResult(
            originalText: text,
            translatedText: translations[toLanguage]!,
            fromLanguage: fromLanguage,
            toLanguage: toLanguage,
            confidence: 0.95,
            isSuccessful: true,
          );
        }
      }

      // Simulate AI translation for complex sentences
      final translatedText = await _simulateTranslation(text, fromLanguage, toLanguage);
      
      return TranslationResult(
        originalText: text,
        translatedText: translatedText,
        fromLanguage: fromLanguage,
        toLanguage: toLanguage,
        confidence: 0.85,
        isSuccessful: true,
      );
    } catch (e) {
      debugPrint('Translation error: $e');
      return TranslationResult(
        originalText: text,
        translatedText: text,
        fromLanguage: fromLanguage,
        toLanguage: toLanguage,
        confidence: 0.0,
        isSuccessful: false,
        error: e.toString(),
      );
    }
  }

  // Simulate AI translation for demo purposes
  Future<String> _simulateTranslation(String text, String from, String to) async {
    // This would normally call a real translation API
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Return a simulated translation with language indicator
    final languageName = supportedLanguages[to] ?? to;
    return '[$languageName] $text';
  }

  // Detect language of input text
  Future<LanguageDetectionResult> detectLanguage(String text) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Simple language detection based on common words
      final lowerText = text.toLowerCase();
      
      if (lowerText.contains('hola') || lowerText.contains('gracias') || lowerText.contains('por favor')) {
        return LanguageDetectionResult(
          detectedLanguage: 'es',
          confidence: 0.9,
          isSuccessful: true,
        );
      } else if (lowerText.contains('bonjour') || lowerText.contains('merci') || lowerText.contains('s\'il vous plaît')) {
        return LanguageDetectionResult(
          detectedLanguage: 'fr',
          confidence: 0.9,
          isSuccessful: true,
        );
      } else if (lowerText.contains('guten tag') || lowerText.contains('danke') || lowerText.contains('bitte')) {
        return LanguageDetectionResult(
          detectedLanguage: 'de',
          confidence: 0.9,
          isSuccessful: true,
        );
      }
      
      // Default to English
      return LanguageDetectionResult(
        detectedLanguage: 'en',
        confidence: 0.7,
        isSuccessful: true,
      );
    } catch (e) {
      return LanguageDetectionResult(
        detectedLanguage: 'en',
        confidence: 0.0,
        isSuccessful: false,
        error: e.toString(),
      );
    }
  }

  // Get supported languages list
  List<String> getSupportedLanguages() {
    return supportedLanguages.keys.toList();
  }

  // Get language display name
  String getLanguageDisplayName(String languageCode) {
    return supportedLanguages[languageCode] ?? languageCode;
  }

  // Check if language is supported
  bool isLanguageSupported(String languageCode) {
    return supportedLanguages.containsKey(languageCode);
  }

  // Translate educational content with context
  Future<TranslationResult> translateEducationalContent({
    required String content,
    required String fromLanguage,
    required String toLanguage,
    String? subject, // math, science, language, etc.
  }) async {
    // Add educational context to improve translation accuracy
    final contextualContent = subject != null 
        ? '[$subject] $content'
        : content;
    
    return await translateText(
      text: contextualContent,
      fromLanguage: fromLanguage,
      toLanguage: toLanguage,
    );
  }
}

class TranslationResult {
  final String originalText;
  final String translatedText;
  final String fromLanguage;
  final String toLanguage;
  final double confidence;
  final bool isSuccessful;
  final String? error;

  TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.fromLanguage,
    required this.toLanguage,
    required this.confidence,
    required this.isSuccessful,
    this.error,
  });

  bool get hasError => error != null;
  bool get isHighConfidence => confidence > 0.8;
  
  String get confidenceLevel {
    if (confidence > 0.9) return 'Very High';
    if (confidence > 0.8) return 'High';
    if (confidence > 0.6) return 'Medium';
    return 'Low';
  }

  @override
  String toString() {
    return 'TranslationResult(from: $fromLanguage, to: $toLanguage, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}

class LanguageDetectionResult {
  final String detectedLanguage;
  final double confidence;
  final bool isSuccessful;
  final String? error;

  LanguageDetectionResult({
    required this.detectedLanguage,
    required this.confidence,
    required this.isSuccessful,
    this.error,
  });

  bool get hasError => error != null;
  bool get isHighConfidence => confidence > 0.8;

  @override
  String toString() {
    return 'LanguageDetectionResult(language: $detectedLanguage, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}
