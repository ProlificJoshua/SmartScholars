import 'package:flutter/material.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/database/database_helper.dart';

class QuizCreationScreen extends StatefulWidget {
  final UserModel user;

  const QuizCreationScreen({super.key, required this.user});

  @override
  State<QuizCreationScreen> createState() => _QuizCreationScreenState();
}

class _QuizCreationScreenState extends State<QuizCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedDifficulty = 'Easy';
  int? _selectedCourseId;
  List<Map<String, dynamic>> _courses = [];
  List<QuizQuestion> _questions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final db = await DatabaseHelper().database;
      final courses = await db.query(
        'courses',
        where: 'createdByUserId = ?',
        whereArgs: [widget.user.id],
      );

      setState(() {
        _courses = courses;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading courses: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 Create Quiz'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _questions.isNotEmpty ? _saveQuiz : null,
            child: const Text(
              'SAVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Quiz details form
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.purple.shade50,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Quiz Title',
                      hintText: 'Enter quiz title',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a quiz title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Enter quiz description',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedCourseId,
                          decoration: const InputDecoration(
                            labelText: 'Course',
                            prefixIcon: Icon(Icons.book),
                          ),
                          items: _courses.map((course) {
                            return DropdownMenuItem<int>(
                              value: course['id'],
                              child: Text(course['title']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCourseId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a course';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedDifficulty,
                          decoration: const InputDecoration(
                            labelText: 'Difficulty',
                            prefixIcon: Icon(Icons.speed),
                          ),
                          items: ['Easy', 'Medium', 'Hard'].map((difficulty) {
                            return DropdownMenuItem<String>(
                              value: difficulty,
                              child: Text(difficulty),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDifficulty = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Questions section
            Expanded(
              child: Column(
                children: [
                  // Questions header
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Questions (${_questions.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addQuestion,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Question'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade600,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Questions list
                  Expanded(
                    child: _questions.isEmpty
                        ? _buildEmptyQuestionsState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _questions.length,
                            itemBuilder: (context, index) {
                              return _buildQuestionCard(
                                _questions[index],
                                index,
                              );
                            },
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

  Widget _buildEmptyQuestionsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No questions added yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Question" to create your first question',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuizQuestion question, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.purple.shade600,
                  radius: 12,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question.question,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editQuestion(index);
                    } else if (value == 'delete') {
                      _deleteQuestion(index);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...question.options.asMap().entries.map((entry) {
              final optionIndex = entry.key;
              final option = entry.value;
              final isCorrect = optionIndex == question.correctAnswerIndex;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      isCorrect
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isCorrect ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${String.fromCharCode(65 + optionIndex)}. $option',
                        style: TextStyle(
                          color: isCorrect
                              ? Colors.green.shade700
                              : Colors.black87,
                          fontWeight: isCorrect
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 8),
            Text(
              'Points: ${question.points}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _addQuestion() {
    _showQuestionDialog();
  }

  void _editQuestion(int index) {
    _showQuestionDialog(question: _questions[index], index: index);
  }

  void _deleteQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  void _showQuestionDialog({QuizQuestion? question, int? index}) {
    showDialog(
      context: context,
      builder: (context) => QuestionDialog(
        question: question,
        onSave: (newQuestion) {
          setState(() {
            if (index != null) {
              _questions[index] = newQuestion;
            } else {
              _questions.add(newQuestion);
            }
          });
        },
      ),
    );
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate() || _questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and add at least one question'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = await DatabaseHelper().database;

      // Insert quiz
      final quizId = await db.insert('quizzes', {
        'courseId': _selectedCourseId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'difficulty': _selectedDifficulty,
        'isPublished': 1,
      });

      // Insert questions
      for (final question in _questions) {
        await db.insert('questions', {
          'quizId': quizId,
          'question': question.question,
          'type': 'multiple_choice',
          'options': question.options.join('|'),
          'correctAnswer': question.options[question.correctAnswerIndex],
          'points': question.points,
        });
      }

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz created successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating quiz: $e')));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final int points;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.points = 1,
  });
}

class QuestionDialog extends StatefulWidget {
  final QuizQuestion? question;
  final Function(QuizQuestion) onSave;

  const QuestionDialog({super.key, this.question, required this.onSave});

  @override
  State<QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<QuestionDialog> {
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  int _correctAnswerIndex = 0;
  int _points = 1;

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      _questionController.text = widget.question!.question;
      for (int i = 0; i < widget.question!.options.length && i < 4; i++) {
        _optionControllers[i].text = widget.question!.options[i];
      }
      _correctAnswerIndex = widget.question!.correctAnswerIndex;
      _points = widget.question!.points;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.question == null ? 'Add Question' : 'Edit Question'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Question',
                hintText: 'Enter your question',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ...List.generate(4, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Radio<int>(
                      value: index,
                      groupValue: _correctAnswerIndex,
                      onChanged: (value) {
                        setState(() {
                          _correctAnswerIndex = value!;
                        });
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _optionControllers[index],
                        decoration: InputDecoration(
                          labelText:
                              'Option ${String.fromCharCode(65 + index)}',
                          hintText: 'Enter option',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Points: '),
                DropdownButton<int>(
                  value: _points,
                  items: List.generate(10, (index) => index + 1)
                      .map(
                        (points) => DropdownMenuItem(
                          value: points,
                          child: Text('$points'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _points = value!;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _saveQuestion, child: const Text('Save')),
      ],
    );
  }

  void _saveQuestion() {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a question')));
      return;
    }

    final options = _optionControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide at least 2 options')),
      );
      return;
    }

    if (_correctAnswerIndex >= options.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid correct answer')),
      );
      return;
    }

    final question = QuizQuestion(
      question: _questionController.text.trim(),
      options: options,
      correctAnswerIndex: _correctAnswerIndex,
      points: _points,
    );

    widget.onSave(question);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
