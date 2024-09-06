import 'package:diploma/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:diploma/api_connection/api_connection.dart';
import '../context/context.dart';
import '../widgets/my_text_field.dart';
import '../widgets/my_text_button.dart';

class QuizScreen extends StatefulWidget {
  final int lectureId;
  final VoidCallback onComplete;

  const QuizScreen({Key? key, required this.lectureId, required this.onComplete}) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  List questions = [];
  int currentQuestionIndex = 0;
  bool allCorrect = true;
  int? userID;
  bool showCorrectMessage = false;
  bool showIncorrectMessage = false;
  bool buttonsEnabled = true;
  String textInput = "";
  TextEditingController? _textController = TextEditingController();

  late AnimationController _correctController;
  late Animation<double> _correctAnimation;

  late AnimationController _incorrectController;
  late Animation<double> _incorrectAnimation;

  @override
  void initState() {
    super.initState();
    userID = UserPreferences.getUserID();
    fetchQuestions();


    _correctController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _correctAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _correctController, curve: Curves.easeInOut),
    );


    _incorrectController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _incorrectAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _incorrectController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _correctController.dispose();
    _incorrectController.dispose();
    _textController?.dispose();
    super.dispose();
  }

  void fetchQuestions() async {
    final response = await http.get(Uri.parse('${API.offlineQuestions}?lecture_id=${widget.lectureId}'));
    if (response.statusCode == 200) {
      setState(() {
        questions = json.decode(response.body);
        _textController = TextEditingController();
      });
    }
  }

  double _calculateProgress() {
    if (questions.isEmpty) return 0;
    return (currentQuestionIndex + 1) / questions.length;
  }

  void submitAnswer({String? selectedOption, String? textAnswer}) async {
    if (questions.isEmpty) return;

    // Close the keyboard
    FocusScope.of(context).unfocus();

    final question = questions[currentQuestionIndex];
    final questionType = question['question_type'];

    final body = {
      'user_id': userID.toString(),
      'question_id': question['id'].toString(),
    };

    if (questionType == 'multiple_choice') {
      body['selected_option'] = selectedOption!;
    } else if (questionType == 'text_input') {
      body['text_answer'] = textAnswer!;
    }

    print(body);
    try {
      final response = await http.post(
        Uri.parse(API.submitAnswerOfflineQuestions),
        body: body,
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        bool answerIsCorrect = result['is_correct'] == 1;

        setState(() {
          buttonsEnabled = false;
          if (answerIsCorrect) {
            showCorrectMessage = true;
            _correctController.forward().then((_) {
              Future.delayed(Duration(seconds: 1), () {
                setState(() {
                  showCorrectMessage = false;
                  _correctController.reset();
                  buttonsEnabled = true;
                  if (currentQuestionIndex < questions.length - 1) {
                    currentQuestionIndex++;
                    _textController?.clear();
                  } else {
                    if (allCorrect) {
                      _updateLectureProgressAndPoints();
                    }
                    Navigator.pop(context);
                  }
                });
              });
            });
          } else {
            allCorrect = false;
            showIncorrectMessage = true;
            _incorrectController.forward().then((_) {
              Future.delayed(Duration(seconds: 1), () {
                setState(() {
                  showIncorrectMessage = false;
                  _incorrectController.reset();
                  buttonsEnabled = true;
                  if (currentQuestionIndex < questions.length - 1) {
                    currentQuestionIndex++;
                    _textController?.clear();
                  } else {
                    Navigator.pop(context);
                  }
                });
              });
            });
          }
        });
      } else {
        print('Error: Failed to submit answer. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception caught: $e');
    }
  }

  void _updateLectureProgressAndPoints() async {
    final response = await http.post(
      Uri.parse(API.updateLectureProgress),
      body: {'user_id': userID.toString()},
    );

    if (response.statusCode == 200) {
      widget.onComplete();
    } else {
      print('Failed to update lecture progress and points');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty || _textController == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Kviz'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      final question = questions[currentQuestionIndex];
      final questionType = question['question_type'];

      return Scaffold(
        appBar: AppBar(
          title: Text(''),
        ),
        body: Column(
          children: [

            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Stack(
                  children: [

                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Color(0xFF32313D) // Dark theme
                            : Colors.grey.shade200, // Light theme
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(5.0),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        width: MediaQuery.of(context).size.width * _calculateProgress(),
                        height: 10,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          question['question_text'],
                          style: TextStyle(fontSize: 24),
                        ),
                        SizedBox(height: 20),
                        if (questionType == 'multiple_choice') ...[
                          GridView.builder(
                            shrinkWrap: true,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: question['options'].length,
                            itemBuilder: (context, i) {
                              final optionKey = question['options'].keys.elementAt(i);
                              final optionValue = question['options'][optionKey];

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.orangeAccent,
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                child: TextButton(
                                  onPressed: buttonsEnabled ? () => submitAnswer(selectedOption: optionKey) : null,
                                  child: Text(
                                    optionValue ?? '',
                                    style: TextStyle(fontSize: 18, color: Colors.white , fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),
                        ] else if (questionType == 'text_input') ...[
                          MyTextField(
                            hintText: 'Tvoj odgovor',
                            inputType: TextInputType.text,
                            fillColor: null,
                            controller: _textController,
                            onChanged: (value) {
                              setState(() {
                                textInput = value;
                              });
                            },
                          ),
                          SizedBox(height: 20),
                          MyTextButton(
                            buttonName: 'Odgovori',
                            onTap: () => submitAnswer(textAnswer: textInput),
                            bgColor: null,
                            textColor: null,
                          ),
                        ],
                        SizedBox(height: 100),
                        if (showCorrectMessage)
                          FadeTransition(
                            opacity: _correctAnimation,
                            child: Text(
                              'Pravilno!',
                              style: TextStyle(
                                fontSize: 48,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (showIncorrectMessage)
                          FadeTransition(
                            opacity: _incorrectAnimation,
                            child: Text(
                              'Nepravilno!',
                              style: TextStyle(
                                fontSize: 48,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}
