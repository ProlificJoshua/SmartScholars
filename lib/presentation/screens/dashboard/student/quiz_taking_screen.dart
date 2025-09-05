import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/services/quiz_service.dart';
import '../../../../core/services/gamification_service.dart';
import '../../../../core/services/answer_verifier_service.dart';
import '../../../../data/models/user_model.dart';

class QuizTakingScreen extends StatefulWidget {
  final Quiz quiz;
  final UserModel user;

  const QuizTakingScreen({
    super.key,
    required this.quiz,
    required this.user,
  });

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  final QuizService _quizService = QuizService();
  final GamificationService _gamificationService = GamificationService();
  final AnswerVerifierService _verifierService = AnswerVerifierService();
  
  QuizWithQuestions? _quizData;
  Map<int, String> _answers = {};
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  Timer? _timer;
  int _timeElapsed = 0;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
    _startTimer();
  }

  Future<void> _loadQuiz() async {
    setState(() => _isLoading = true);
    
    try {
      final quizData = await _quizService.getQuizWithQuestions(widget.quiz.id);
      
      setState(() {
        _quizData = quizData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading quiz: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeElapsed++;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.quiz.title),
          backgroundColor: Colors.purple.shade600,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_quizData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.quiz.title),
          backgroundColor: Colors.purple.shade600,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Quiz not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _formatTime(_timeElapsed),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: _buildQuestionContent(),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final progress = (_currentQuestionIndex + 1) / _quizData!.questions.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.purple.shade50,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${_quizData!.questions.length}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${(progress * 100).toInt()}% Complete',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent() {
    final question = _quizData!.questions[_currentQuestionIndex];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.question,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...question.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final optionLetter = String.fromCharCode(65 + index);
                    final isSelected = _answers[question.id] == option;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => _selectAnswer(question.id, option),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected 
                                  ? Colors.purple.shade600 
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: isSelected 
                                ? Colors.purple.shade50 
                                : Colors.white,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected 
                                      ? Colors.purple.shade600 
                                      : Colors.grey.shade300,
                                ),
                                child: Center(
                                  child: Text(
                                    optionLetter,
                                    style: TextStyle(
                                      color: isSelected 
                                          ? Colors.white 
                                          : Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isSelected 
                                        ? Colors.purple.shade700 
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Answer verification hint
          if (_answers.containsKey(question.id))
            FutureBuilder<AnswerVerificationResult>(
              future: _verifierService.verifyAnswer(
                question: question.question,
                studentAnswer: _answers[question.id]!,
                correctAnswer: question.correctAnswer,
                subject: widget.quiz.title.toLowerCase().contains('math') ? 'math' : 'general',
              ),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final result = snapshot.data!;
                  return Card(
                    color: result.isCorrect ? Colors.green.shade50 : Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            result.isCorrect ? Icons.check_circle : Icons.info,
                            color: result.isCorrect ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              result.isCorrect 
                                  ? 'Good answer! Confidence: ${result.confidencePercentage}'
                                  : 'Consider reviewing this answer. Confidence: ${result.confidencePercentage}',
                              style: TextStyle(
                                color: result.isCorrect ? Colors.green.shade700 : Colors.orange.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final isLastQuestion = _currentQuestionIndex == _quizData!.questions.length - 1;
    final canGoNext = _currentQuestionIndex < _quizData!.questions.length - 1;
    final canGoPrevious = _currentQuestionIndex > 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (canGoPrevious)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousQuestion,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
              ),
            ),
          if (canGoPrevious && (canGoNext || isLastQuestion))
            const SizedBox(width: 16),
          if (canGoNext)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _nextQuestion,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          if (isLastQuestion && !canGoNext)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitQuiz,
                icon: _isSubmitting 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_isSubmitting ? 'Submitting...' : 'Submit Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _selectAnswer(int questionId, String answer) {
    setState(() {
      _answers[questionId] = answer;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _quizData!.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  Future<void> _submitQuiz() async {
    // Check if all questions are answered
    final unansweredQuestions = _quizData!.questions
        .where((q) => !_answers.containsKey(q.id))
        .toList();

    if (unansweredQuestions.isNotEmpty) {
      final shouldSubmit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Incomplete Quiz'),
          content: Text(
            'You have ${unansweredQuestions.length} unanswered questions. '
            'Do you want to submit anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continue Quiz'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit Anyway'),
            ),
          ],
        ),
      );

      if (shouldSubmit != true) return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _quizService.submitQuizAttempt(
        quizId: widget.quiz.id,
        userId: widget.user.id!,
        answers: _answers,
        timeTaken: _timeElapsed,
      );

      // Award gamification points
      await _gamificationService.awardPoints(
        userId: widget.user.id!,
        activity: result.score == 100 ? 'quiz_perfect_score' : 'quiz_completed',
        description: 'Completed ${widget.quiz.title} with ${result.score}%',
      );

      // Show results
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Quiz Completed!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  result.score >= 70 ? Icons.celebration : Icons.info,
                  size: 48,
                  color: result.score >= 70 ? Colors.green : Colors.orange,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Score: ${result.score}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Grade: ${result.grade}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  '${result.correctAnswers} out of ${result.totalQuestions} correct',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Text(
                  'Time taken: ${_formatTime(_timeElapsed)}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to quiz list
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting quiz: $e')),
        );
      }
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
