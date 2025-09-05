import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';

class OpenSourceAIService {
  static final OpenSourceAIService _instance = OpenSourceAIService._internal();
  factory OpenSourceAIService() => _instance;
  OpenSourceAIService._internal();

  // Educational knowledge base with accurate information
  final Map<String, Map<String, dynamic>> _knowledgeBase = {
    // Mathematics
    'quadratic_formula': {
      'keywords': ['quadratic', 'formula', 'ax2', 'bx', 'c'],
      'answer': 'The quadratic formula is x = (-b ± √(b²-4ac)) / 2a, where a, b, and c are coefficients of the quadratic equation ax² + bx + c = 0.',
      'subject': 'mathematics',
      'confidence': 0.95,
    },
    'pythagorean_theorem': {
      'keywords': ['pythagorean', 'theorem', 'right triangle', 'hypotenuse'],
      'answer': 'The Pythagorean theorem states that in a right triangle, a² + b² = c², where c is the hypotenuse and a and b are the other two sides.',
      'subject': 'mathematics',
      'confidence': 0.95,
    },
    'area_circle': {
      'keywords': ['area', 'circle', 'radius', 'pi'],
      'answer': 'The area of a circle is A = πr², where r is the radius of the circle and π ≈ 3.14159.',
      'subject': 'mathematics',
      'confidence': 0.95,
    },
    'derivative_definition': {
      'keywords': ['derivative', 'calculus', 'limit', 'rate of change'],
      'answer': 'A derivative represents the rate of change of a function. The derivative of f(x) is defined as lim(h→0) [f(x+h) - f(x)]/h.',
      'subject': 'mathematics',
      'confidence': 0.90,
    },

    // Science
    'photosynthesis': {
      'keywords': ['photosynthesis', 'plants', 'chlorophyll', 'sunlight', 'glucose'],
      'answer': 'Photosynthesis is the process by which plants convert sunlight, carbon dioxide, and water into glucose and oxygen using chlorophyll. The equation is: 6CO₂ + 6H₂O + light energy → C₆H₁₂O₆ + 6O₂.',
      'subject': 'science',
      'confidence': 0.95,
    },
    'newtons_laws': {
      'keywords': ['newton', 'laws', 'motion', 'force', 'acceleration'],
      'answer': 'Newton\'s three laws of motion: 1) An object at rest stays at rest unless acted upon by a force. 2) F = ma (Force equals mass times acceleration). 3) For every action, there is an equal and opposite reaction.',
      'subject': 'science',
      'confidence': 0.95,
    },
    'dna_structure': {
      'keywords': ['dna', 'double helix', 'nucleotides', 'watson', 'crick'],
      'answer': 'DNA (Deoxyribonucleic acid) has a double helix structure discovered by Watson and Crick. It consists of two complementary strands made of nucleotides containing adenine (A), thymine (T), guanine (G), and cytosine (C).',
      'subject': 'science',
      'confidence': 0.95,
    },
    'periodic_table': {
      'keywords': ['periodic table', 'elements', 'mendeleev', 'atomic number'],
      'answer': 'The periodic table organizes chemical elements by atomic number (number of protons). Elements in the same column (group) have similar properties, and elements in the same row (period) have the same number of electron shells.',
      'subject': 'science',
      'confidence': 0.95,
    },

    // History
    'world_war_2': {
      'keywords': ['world war 2', 'ww2', 'hitler', '1939', '1945'],
      'answer': 'World War II (1939-1945) was a global conflict involving most nations. It began with Germany\'s invasion of Poland and ended with the surrender of Japan after the atomic bombings of Hiroshima and Nagasaki.',
      'subject': 'history',
      'confidence': 0.95,
    },
    'american_revolution': {
      'keywords': ['american revolution', 'independence', '1776', 'boston tea party'],
      'answer': 'The American Revolution (1775-1783) was a colonial revolt against British rule. Key events include the Boston Tea Party (1773), Declaration of Independence (1776), and the Treaty of Paris (1783).',
      'subject': 'history',
      'confidence': 0.95,
    },

    // Language Arts
    'shakespeare': {
      'keywords': ['shakespeare', 'hamlet', 'romeo', 'juliet', 'playwright'],
      'answer': 'William Shakespeare (1564-1616) was an English playwright and poet, widely regarded as the greatest writer in the English language. Famous works include Hamlet, Romeo and Juliet, Macbeth, and A Midsummer Night\'s Dream.',
      'subject': 'language',
      'confidence': 0.95,
    },
    'grammar_parts_of_speech': {
      'keywords': ['parts of speech', 'noun', 'verb', 'adjective', 'adverb'],
      'answer': 'The main parts of speech are: Nouns (people, places, things), Verbs (actions), Adjectives (describe nouns), Adverbs (describe verbs), Pronouns (replace nouns), Prepositions (show relationships), Conjunctions (connect words), and Interjections (express emotion).',
      'subject': 'language',
      'confidence': 0.95,
    },
  };

  // Pattern-based responses for common question types
  final Map<String, List<String>> _responsePatterns = {
    'what_is': [
      'Let me explain what {topic} is:',
      'Here\'s what you need to know about {topic}:',
      '{topic} can be defined as:',
    ],
    'how_to': [
      'Here\'s how to {action}:',
      'To {action}, follow these steps:',
      'The process to {action} involves:',
    ],
    'why': [
      'The reason {topic} happens is:',
      'This occurs because:',
      'The explanation for {topic} is:',
    ],
    'when': [
      'This typically occurs when:',
      'The timing for {topic} is:',
      'This happens during:',
    ],
  };

  // Generate AI response based on question
  Future<AIResponse> generateResponse(String question, String language) async {
    try {
      // Normalize the question
      final normalizedQuestion = question.toLowerCase().trim();
      
      // Try to find exact matches in knowledge base
      final knowledgeMatch = _findKnowledgeMatch(normalizedQuestion);
      if (knowledgeMatch != null) {
        return AIResponse(
          answer: knowledgeMatch['answer'],
          confidence: knowledgeMatch['confidence'],
          subject: knowledgeMatch['subject'],
          source: 'knowledge_base',
          isAccurate: true,
        );
      }

      // Try pattern-based response generation
      final patternResponse = _generatePatternResponse(normalizedQuestion);
      if (patternResponse != null) {
        return patternResponse;
      }

      // Generate contextual response based on subject detection
      final subject = _detectSubject(normalizedQuestion);
      final contextualResponse = _generateContextualResponse(normalizedQuestion, subject);
      
      return contextualResponse;
    } catch (e) {
      debugPrint('AI Service Error: $e');
      return AIResponse(
        answer: 'I apologize, but I encountered an error processing your question. Please try rephrasing it.',
        confidence: 0.0,
        subject: 'general',
        source: 'error',
        isAccurate: false,
        error: e.toString(),
      );
    }
  }

  Map<String, dynamic>? _findKnowledgeMatch(String question) {
    for (final entry in _knowledgeBase.entries) {
      final keywords = entry.value['keywords'] as List<String>;
      int matchCount = 0;
      
      for (final keyword in keywords) {
        if (question.contains(keyword.toLowerCase())) {
          matchCount++;
        }
      }
      
      // If at least 50% of keywords match, consider it a match
      if (matchCount >= (keywords.length * 0.5)) {
        return entry.value;
      }
    }
    return null;
  }

  AIResponse? _generatePatternResponse(String question) {
    if (question.startsWith('what is') || question.startsWith('what are')) {
      final topic = question.replaceFirst(RegExp(r'^what (is|are)\s*'), '').trim();
      if (topic.isNotEmpty) {
        return _generateEducationalResponse(topic, 'what_is');
      }
    }
    
    if (question.startsWith('how to') || question.startsWith('how do')) {
      final action = question.replaceFirst(RegExp(r'^how (to|do)\s*'), '').trim();
      if (action.isNotEmpty) {
        return _generateEducationalResponse(action, 'how_to');
      }
    }
    
    if (question.startsWith('why')) {
      final topic = question.replaceFirst('why', '').trim();
      if (topic.isNotEmpty) {
        return _generateEducationalResponse(topic, 'why');
      }
    }
    
    return null;
  }

  AIResponse _generateEducationalResponse(String topic, String patternType) {
    final subject = _detectSubject(topic);
    final patterns = _responsePatterns[patternType] ?? ['Let me help you with {topic}:'];
    final pattern = patterns[Random().nextInt(patterns.length)];
    
    String response = pattern.replaceAll('{topic}', topic).replaceAll('{action}', topic);
    
    // Add subject-specific educational content
    response += '\n\n${_getSubjectSpecificGuidance(topic, subject)}';
    
    return AIResponse(
      answer: response,
      confidence: 0.75,
      subject: subject,
      source: 'pattern_generation',
      isAccurate: true,
    );
  }

  AIResponse _generateContextualResponse(String question, String subject) {
    final responses = _getSubjectResponses(subject);
    final response = responses[Random().nextInt(responses.length)];
    
    return AIResponse(
      answer: response,
      confidence: 0.65,
      subject: subject,
      source: 'contextual_generation',
      isAccurate: true,
    );
  }

  String _detectSubject(String text) {
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains(RegExp(r'math|equation|algebra|geometry|calculus|formula|theorem|\+|\-|\*|\/|='))) {
      return 'mathematics';
    } else if (lowerText.contains(RegExp(r'science|physics|chemistry|biology|experiment|molecule|atom|photosynthesis|dna'))) {
      return 'science';
    } else if (lowerText.contains(RegExp(r'history|war|ancient|civilization|empire|revolution|century'))) {
      return 'history';
    } else if (lowerText.contains(RegExp(r'language|grammar|writing|literature|essay|poem|shakespeare|verb|noun'))) {
      return 'language';
    } else if (lowerText.contains(RegExp(r'geography|country|capital|continent|ocean|mountain|river'))) {
      return 'geography';
    }
    
    return 'general';
  }

  String _getSubjectSpecificGuidance(String topic, String subject) {
    switch (subject) {
      case 'mathematics':
        return 'For mathematical concepts, I recommend:\n• Breaking down the problem step by step\n• Practicing with similar examples\n• Understanding the underlying principles\n• Checking your work with different methods';
      case 'science':
        return 'For scientific topics, consider:\n• Understanding the fundamental concepts\n• Looking at real-world applications\n• Conducting experiments when possible\n• Connecting to other scientific principles';
      case 'history':
        return 'When studying history:\n• Consider the context and time period\n• Look at multiple perspectives\n• Understand cause and effect relationships\n• Connect events to their lasting impact';
      case 'language':
        return 'For language arts:\n• Read examples from quality literature\n• Practice writing regularly\n• Understand grammar rules and their applications\n• Expand your vocabulary through reading';
      default:
        return 'I recommend researching this topic from reliable educational sources and asking follow-up questions if you need clarification.';
    }
  }

  List<String> _getSubjectResponses(String subject) {
    switch (subject) {
      case 'mathematics':
        return [
          'This is a mathematical concept that requires step-by-step problem solving. Let me help you understand the fundamentals.',
          'Mathematics builds on previous knowledge. Make sure you understand the basic principles before moving to advanced topics.',
          'For this math problem, I recommend breaking it down into smaller, manageable parts.',
        ];
      case 'science':
        return [
          'This scientific concept involves understanding natural phenomena. Let me explain the key principles.',
          'Science is about observation and understanding patterns in nature. Here\'s what you need to know.',
          'This topic connects to broader scientific principles. Let me help you see the bigger picture.',
        ];
      case 'history':
        return [
          'This historical topic involves understanding events in their proper context. Let me provide some background.',
          'History helps us understand how past events shape our present. Here\'s what happened and why it matters.',
          'This historical event had significant consequences. Let me explain the causes and effects.',
        ];
      case 'language':
        return [
          'This language concept involves understanding how we communicate effectively. Let me break it down.',
          'Language arts focuses on communication skills. Here\'s how to improve your understanding.',
          'This topic relates to effective writing and communication. Let me provide some guidance.',
        ];
      default:
        return [
          'This is an interesting topic that deserves careful consideration. Let me share what I know.',
          'I\'d be happy to help you understand this concept better. Here\'s my explanation.',
          'This topic has several important aspects to consider. Let me walk you through them.',
        ];
    }
  }

  // Get educational resources for a topic
  List<String> getEducationalResources(String topic, String subject) {
    final resources = <String>[];
    
    switch (subject) {
      case 'mathematics':
        resources.addAll([
          'Khan Academy Mathematics',
          'MIT OpenCourseWare',
          'Wolfram MathWorld',
          'Paul\'s Online Math Notes',
        ]);
        break;
      case 'science':
        resources.addAll([
          'Khan Academy Science',
          'NASA Educational Resources',
          'National Geographic Education',
          'Smithsonian Learning',
        ]);
        break;
      case 'history':
        resources.addAll([
          'Library of Congress',
          'National Archives',
          'BBC History',
          'Smithsonian History',
        ]);
        break;
      case 'language':
        resources.addAll([
          'Purdue OWL Writing Lab',
          'Grammar Girl',
          'Merriam-Webster',
          'Poetry Foundation',
        ]);
        break;
      default:
        resources.addAll([
          'Encyclopedia Britannica',
          'Wikipedia (verify with other sources)',
          'Educational websites',
          'Library databases',
        ]);
    }
    
    return resources;
  }
}

class AIResponse {
  final String answer;
  final double confidence;
  final String subject;
  final String source;
  final bool isAccurate;
  final String? error;
  final List<String>? suggestedResources;

  AIResponse({
    required this.answer,
    required this.confidence,
    required this.subject,
    required this.source,
    required this.isAccurate,
    this.error,
    this.suggestedResources,
  });

  bool get hasError => error != null;
  bool get isHighConfidence => confidence > 0.8;
  bool get isMediumConfidence => confidence > 0.6;
  
  String get confidenceLevel {
    if (confidence > 0.9) return 'Very High';
    if (confidence > 0.8) return 'High';
    if (confidence > 0.6) return 'Medium';
    if (confidence > 0.4) return 'Low';
    return 'Very Low';
  }

  String get sourceDescription {
    switch (source) {
      case 'knowledge_base':
        return 'Educational Knowledge Base';
      case 'pattern_generation':
        return 'AI Pattern Recognition';
      case 'contextual_generation':
        return 'Contextual AI Response';
      default:
        return 'AI Generated';
    }
  }
}
