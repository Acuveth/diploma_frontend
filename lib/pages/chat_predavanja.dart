import 'package:diploma/api_connection/api_connection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../context/context.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController textEditingController = TextEditingController();
  List messages = [];
  int? userID;
  Timer? _timer;
  Timer? _questionTimer;
  double _progressWidth = 1.0;
  final int questionDuration = 10; // duration in seconds
  Map<String, dynamic>? activeQuestion;
  int? lastFetchedQuestionId;
  bool isAnswerSubmitted = false; // Track if the user has submitted an answer
  final ScrollController _scrollController = ScrollController(); // Scroll controller for ListView
  DateTime? questionActivationTime;
  late AnimationController _animationController;
  bool _isControllerInitialized = false;  // Flag to track initialization

  @override
  void initState() {
    super.initState();
    userID = UserPreferences.getUserID();
    fetchMessages();
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      fetchMessages();
    });
    fetchActiveQuestion(); // Fetch the first question when the screen loads

    // Initialize the animation controller for blinking effect
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000), // Blink duration
      vsync: this,
    )..repeat(reverse: true); // Repeat the animation in reverse to create blinking effect

    _isControllerInitialized = true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _questionTimer?.cancel();
    textEditingController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchActiveQuestion() async {
    final response = await http.get(Uri.parse(API.getActiveQuestion));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] != 'no_active_question') {
        int currentQuestionId = int.parse(data['id'].toString());
        if (lastFetchedQuestionId != currentQuestionId) {
          setState(() {
            activeQuestion = data;
            lastFetchedQuestionId = currentQuestionId;
            questionActivationTime = DateTime.now();
            _startQuestionTimer();
          });
        }
      } else {
        setState(() {
          activeQuestion = null;
        });
      }
    }
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel(); // Cancel any existing timer
    setState(() {
      _progressWidth = 1.0; // Reset progress bar width
      isAnswerSubmitted = false;  // Allow new answer submission when a new question starts
    });

    int tick = 0;
    int totalTicks = questionDuration * 10;

    _questionTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      setState(() {
        tick++;
        _progressWidth = 1.0 - (tick / totalTicks); // Decrease progress bar width

        if (tick >= totalTicks) {
          _progressWidth = 0;
          timer.cancel();

          // If the user hasn't submitted the answer, submit a wrong answer
          if (!isAnswerSubmitted) {
            _submitTimeoutAnswer();
          }

          // Wait for the timer to finish, then fetch the next question
          Future.delayed(Duration(seconds: 1), () {
            fetchActiveQuestion();
          });
        }
      });
    });
  }

  Future<void> _submitTimeoutAnswer() async {
    if (activeQuestion != null && userID != null) {
      await submitAnswer('F');  // Submit a wrong answer 'F' when the user doesn't answer on time
    }
  }

  Future<void> submitAnswer(String selectedOption) async {
    if (isAnswerSubmitted) return; // Avoid double submission
    setState(() {
      isAnswerSubmitted = true;
    });

    final questionId = activeQuestion?['id'];
    if (questionId == null || userID == null || questionActivationTime == null) return;

    final DateTime submitTime = DateTime.now(); // Capture the submission time
    final response = await http.post(
      Uri.parse(API.submitAnswerLiveQuestion),
      body: {
        'user_id': userID.toString(),
        'question_id': questionId.toString(),
        'selected_option': selectedOption,
        'activation_time': questionActivationTime?.toIso8601String(),
        'submit_time': submitTime.toIso8601String(),
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['is_correct'] == 1) {
        final points = data['points'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Pravilno! Dobil si $points točk!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Nepravilen odgovor.")),
        );
      }
    }
  }

  Future<void> fetchMessages() async {
    final response = await http.get(Uri.parse(API.getMessages));
    if (response.statusCode == 200) {
      if (mounted) {
        setState(() {
          messages = json.decode(response.body);
        });


        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } else {
      throw Exception('Failed to load messages');
    }
  }


  Future<void> sendMessage(String message) async {
    if (userID == null) {
      // Handle user not logged in
      return;
    }

    final response = await http.post(
      Uri.parse(API.sendMessages),
      body: {'user_id': userID.toString(), 'message': message},
    );
    if (response.statusCode == 200) {
      fetchMessages();
    } else {
      throw Exception('Failed to send message');
    }
  }

  void _handleSendMessage() {
    if (textEditingController.text.isNotEmpty) {
      sendMessage(textEditingController.text);
      textEditingController.clear();


      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }



  Future<void> _handleRefresh() async {
    await fetchMessages();
    await fetchActiveQuestion();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isControllerInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _animationController.value,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
            SizedBox(width: 8),
            Text("Klepet v živo",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            )
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Chat UI
          Column(
            children: <Widget>[
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: false,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final reversedIndex = messages.length - 1 - index;
                      final message = messages[reversedIndex];
                      final messageText = message['message'] ?? 'No message';
                      final timestamp = message['timestamp'] ?? 'No timestamp';
                      final messageUserID = message['user_id'] ?? 'Unknown';

                      // Parse the timestamp to a DateTime object
                      DateTime dateTime = DateTime.parse(timestamp);

                      // Format the time part of the DateTime
                      String timeOnly = DateFormat('HH:mm').format(dateTime);

                      // Determine if the message was sent by the current user
                      bool isCurrentUser = messageUserID.toString() == userID?.toString();

                      return Align(
                        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          decoration: BoxDecoration(
                            color: isCurrentUser ? Colors.orangeAccent : Colors.grey[300],
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                              bottomLeft: isCurrentUser ? Radius.circular(10) : Radius.circular(0),
                              bottomRight: isCurrentUser ? Radius.circular(0) : Radius.circular(10),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                messageText,
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                timeOnly,
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: textEditingController,
                        decoration: InputDecoration(
                          hintText: "Napiši sporočilo...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: _handleSendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),


          if (activeQuestion != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            AnimatedContainer(
                              duration: Duration(milliseconds: 100),
                              width: MediaQuery.of(context).size.width * _progressWidth,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Text(
                          activeQuestion!['question_text'],
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          childAspectRatio: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          children: [
                            ElevatedButton(
                              onPressed: isAnswerSubmitted ? null : () => submitAnswer('A'),
                              child: Text(activeQuestion!['option_a'], style: TextStyle(color: Colors.white),),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.blue,
                                padding: EdgeInsets.symmetric(vertical: 15),
                                textStyle: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: isAnswerSubmitted ? null : () => submitAnswer('B'),
                              child: Text(activeQuestion!['option_b'], style: TextStyle(color: Colors.white),),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.green,
                                padding: EdgeInsets.symmetric(vertical: 15),
                                textStyle: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: isAnswerSubmitted ? null : () => submitAnswer('C'),
                              child: Text(activeQuestion!['option_c'], style: TextStyle(color: Colors.white),),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.orange,
                                padding: EdgeInsets.symmetric(vertical: 15),
                                textStyle: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: isAnswerSubmitted ? null : () => submitAnswer('D'),
                              child: Text(activeQuestion!['option_d'], style: TextStyle(color: Colors.white),),
                              style: ElevatedButton.styleFrom(
                                primary: Colors.red,
                                padding: EdgeInsets.symmetric(vertical: 15),
                                textStyle: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
