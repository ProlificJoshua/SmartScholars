import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

class AnswerVerifierService {
  static final AnswerVerifierService _instance = AnswerVerifierService._internal();
  factory AnswerVerifierService() => _instance;
  AnswerVerifierService._internal();

  // Knowledge base for answer verification
  final Map<String, List<String>> _knowledgeBase = {
    // Math answers
    '2+2': ['4', 'four'],
    '5*3': ['15', 'fifteen'],
    '10/2': ['5', 'five'],
    'square root of 16': ['4', 'four'],
    'area of circle': ['πr²', 'pi r squared', 'π × r²'],
    
    // Science answers
    'photosynthesis': [
      'process by which plants make food using sunlight',
      'plants convert sunlight into energy',
      'chlorophyll absorbs light energy'
    ],
    'water formula': ['H2O', 'h2o'],
    'speed of light': ['299792458 m/s', '3×10^8 m/s', 'approximately 300,000 km/s'],
    
    // Geography answers
    'capital of france': ['paris'],
    'capital of spain': ['madrid'],
    'capital of italy': ['rome'],
    'largest ocean': ['pacific', 'pacific ocean'],
    
    // History answers
    'world war 2 ended': ['1945'],
    'first moon landing': ['1969', 'july 20 1969'],
  };

  // Common plagiarism sources (for demo)
  final List<String> _commonSources = [
    'Wikipedia',
    'Encyclopedia Britannica',
    'Khan Academy',
    'National Geographic',
    'Scientific American',
    'BBC Education',
    'Coursera',
    'edX',
    'MIT OpenCourseWare',
    'Stanford Online',
  ];

  // Verify answer accuracy
  Future<AnswerVerificationResult> verifyAnswer({
    required String question,
    required String studentAnswer,
    required String? correctAnswer,
    String? subject,
  }) async {
    try {
      // Simulate processing time
      await Future.delayed(const Duration(milliseconds: 800));

      final normalizedQuestion = question.toLowerCase().trim();
      final normalizedStudentAnswer = studentAnswer.toLowerCase().trim();
      final normalizedCorrectAnswer = correctAnswer?.toLowerCase().trim();

      // Check against knowledge base
      double accuracy = 0.0;
      List<String> suggestions = [];
      
      if (_knowledgeBase.containsKey(normalizedQuestion)) {
        final possibleAnswers = _knowledgeBase[normalizedQuestion]!;
        for (final answer in possibleAnswers) {
          if (normalizedStudentAnswer.contains(answer.toLowerCase())) {
            accuracy = 0.95;
            break;
          }
        }
        
        if (accuracy < 0.5) {
          suggestions = possibleAnswers.take(3).toList();
        }
      } else if (normalizedCorrectAnswer != null) {
        // Compare with provided correct answer
        accuracy = _calculateSimilarity(normalizedStudentAnswer, normalizedCorrectAnswer);
        if (accuracy < 0.7) {
          suggestions = [correctAnswer!];
        }
      } else {
        // Use AI-like scoring for unknown questions
        accuracy = _simulateAIScoring(normalizedStudentAnswer, subject);
      }

      return AnswerVerificationResult(
        question: question,
        studentAnswer: studentAnswer,
        correctAnswer: correctAnswer,
        accuracy: accuracy,
        confidence: _calculateConfidence(accuracy),
        isCorrect: accuracy >= 0.7,
        suggestions: suggestions,
        feedback: _generateFeedback(accuracy, subject),
        subject: subject,
      );
    } catch (e) {
      debugPrint('Answer verification error: $e');
      return AnswerVerificationResult(
        question: question,
        studentAnswer: studentAnswer,
        correctAnswer: correctAnswer,
        accuracy: 0.0,
        confidence: 0.0,
        isCorrect: false,
        suggestions: [],
        feedback: 'Unable to verify answer due to technical error.',
        subject: subject,
        error: e.toString(),
      );
    }
  }

  // Check for plagiarism
  Future<PlagiarismResult> checkPlagiarism({
    required String text,
    String? subject,
  }) async {
    try {
      // Simulate plagiarism checking time
      await Future.delayed(const Duration(milliseconds: 1200));

      final normalizedText = text.toLowerCase().trim();
      
      // Simulate plagiarism detection
      double plagiarismScore = 0.0;
      List<PlagiarismMatch> matches = [];
      
      // Check for common phrases that might indicate copying
      final suspiciousPatterns = [
        'according to wikipedia',
        'as stated in',
        'copy and paste',
        'source:',
        'retrieved from',
      ];

      for (final pattern in suspiciousPatterns) {
        if (normalizedText.contains(pattern)) {
          plagiarismScore += 0.2;
          matches.add(PlagiarismMatch(
            matchedText: pattern,
            source: _getRandomSource(),
            similarity: 0.8 + Random().nextDouble() * 0.2,
            startIndex: normalizedText.indexOf(pattern),
            endIndex: normalizedText.indexOf(pattern) + pattern.length,
          ));
        }
      }

      // Simulate additional matches based on text length and complexity
      if (text.length > 200) {
        final additionalMatches = Random().nextInt(3);
        for (int i = 0; i < additionalMatches; i++) {
          matches.add(PlagiarismMatch(
            matchedText: _extractRandomPhrase(text),
            source: _getRandomSource(),
            similarity: 0.6 + Random().nextDouble() * 0.3,
            startIndex: Random().nextInt(text.length ~/ 2),
            endIndex: Random().nextInt(text.length ~/ 2) + 50,
          ));
          plagiarismScore += 0.1;
        }
      }

      plagiarismScore = plagiarismScore.clamp(0.0, 1.0);

      return PlagiarismResult(
        originalText: text,
        plagiarismScore: plagiarismScore,
        isOriginal: plagiarismScore < 0.3,
        confidence: 0.85 + Random().nextDouble() * 0.1,
        matches: matches,
        recommendation: _getPlagiarismRecommendation(plagiarismScore),
        subject: subject,
      );
    } catch (e) {
      debugPrint('Plagiarism check error: $e');
      return PlagiarismResult(
        originalText: text,
        plagiarismScore: 0.0,
        isOriginal: true,
        confidence: 0.0,
        matches: [],
        recommendation: 'Unable to check plagiarism due to technical error.',
        subject: subject,
        error: e.toString(),
      );
    }
  }

  // Calculate similarity between two strings
  double _calculateSimilarity(String text1, String text2) {
    if (text1 == text2) return 1.0;
    
    final words1 = text1.split(' ');
    final words2 = text2.split(' ');
    
    int commonWords = 0;
    for (final word in words1) {
      if (words2.contains(word)) {
        commonWords++;
      }
    }
    
    final maxWords = max(words1.length, words2.length);
    return maxWords > 0 ? commonWords / maxWords : 0.0;
  }

  // Simulate AI scoring
  double _simulateAIScoring(String answer, String? subject) {
    // Base score on answer length and complexity
    double score = 0.5;
    
    if (answer.length > 10) score += 0.1;
    if (answer.length > 50) score += 0.1;
    if (answer.contains(' ')) score += 0.1; // Multiple words
    if (RegExp(r'\d').hasMatch(answer)) score += 0.1; // Contains numbers
    
    // Subject-specific bonuses
    if (subject == 'math' && RegExp(r'[\+\-\*\/\=]').hasMatch(answer)) {
      score += 0.2;
    } else if (subject == 'science' && answer.contains(RegExp(r'(process|energy|molecule|atom)'))) {
      score += 0.2;
    }
    
    return score.clamp(0.0, 1.0);
  }

  // Calculate confidence score
  double _calculateConfidence(double accuracy) {
    if (accuracy > 0.9) return 0.95;
    if (accuracy > 0.8) return 0.85;
    if (accuracy > 0.6) return 0.75;
    return 0.6;
  }

  // Generate feedback based on accuracy
  String _generateFeedback(double accuracy, String? subject) {
    if (accuracy >= 0.9) {
      return '🎉 Excellent! Your answer is highly accurate.';
    } else if (accuracy >= 0.7) {
      return '✅ Good answer! Minor improvements could be made.';
    } else if (accuracy >= 0.5) {
      return '⚠️ Partially correct. Please review and improve your answer.';
    } else {
      return '❌ This answer needs significant improvement. Consider reviewing the material.';
    }
  }

  // Get random source for plagiarism simulation
  String _getRandomSource() {
    return _commonSources[Random().nextInt(_commonSources.length)];
  }

  // Extract random phrase for plagiarism simulation
  String _extractRandomPhrase(String text) {
    final words = text.split(' ');
    if (words.length < 5) return text;
    
    final startIndex = Random().nextInt(words.length - 4);
    return words.sublist(startIndex, startIndex + 5).join(' ');
  }

  // Get plagiarism recommendation
  String _getPlagiarismRecommendation(double score) {
    if (score < 0.1) {
      return '✅ Original work - No plagiarism detected.';
    } else if (score < 0.3) {
      return '⚠️ Low similarity detected - Likely original with some common phrases.';
    } else if (score < 0.6) {
      return '🔍 Moderate similarity - Please review and cite sources properly.';
    } else {
      return '❌ High similarity detected - Significant plagiarism concerns.';
    }
  }
}

class AnswerVerificationResult {
  final String question;
  final String studentAnswer;
  final String? correctAnswer;
  final double accuracy;
  final double confidence;
  final bool isCorrect;
  final List<String> suggestions;
  final String feedback;
  final String? subject;
  final String? error;

  AnswerVerificationResult({
    required this.question,
    required this.studentAnswer,
    this.correctAnswer,
    required this.accuracy,
    required this.confidence,
    required this.isCorrect,
    required this.suggestions,
    required this.feedback,
    this.subject,
    this.error,
  });

  bool get hasError => error != null;
  String get accuracyPercentage => '${(accuracy * 100).toStringAsFixed(1)}%';
  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(1)}%';
}

class PlagiarismResult {
  final String originalText;
  final double plagiarismScore;
  final bool isOriginal;
  final double confidence;
  final List<PlagiarismMatch> matches;
  final String recommendation;
  final String? subject;
  final String? error;

  PlagiarismResult({
    required this.originalText,
    required this.plagiarismScore,
    required this.isOriginal,
    required this.confidence,
    required this.matches,
    required this.recommendation,
    this.subject,
    this.error,
  });

  bool get hasError => error != null;
  String get plagiarismPercentage => '${(plagiarismScore * 100).toStringAsFixed(1)}%';
  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(1)}%';
}

class PlagiarismMatch {
  final String matchedText;
  final String source;
  final double similarity;
  final int startIndex;
  final int endIndex;

  PlagiarismMatch({
    required this.matchedText,
    required this.source,
    required this.similarity,
    required this.startIndex,
    required this.endIndex,
  });

  String get similarityPercentage => '${(similarity * 100).toStringAsFixed(1)}%';
}
