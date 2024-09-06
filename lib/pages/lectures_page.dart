import 'package:flutter/material.dart';
import 'quiz_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:diploma/api_connection/api_connection.dart';
import '../context/context.dart';

class LecturesPage extends StatefulWidget {
  const LecturesPage({Key? key}) : super(key: key);

  @override
  _LecturesPageState createState() => _LecturesPageState();
}

class _LecturesPageState extends State<LecturesPage> {
  final List<bool> _isLectureUnlocked = List.generate(13, (index) => index == 0);
  int? userID;
  int? lectureProgress;
  int userPoints = 0;


  final List<String> lectureIcons = [
    'assets/Ena.png',
    'assets/Dva.png',
    'assets/Tri.png',
    'assets/Stiri.png',
    'assets/Pet.png',
    'assets/Sest.png',
    'assets/Sedem.png',
    'assets/Osem.png',
    'assets/Devet.png',
    'assets/Deset.png',
    'assets/Enajst.png',
    'assets/Dvanajst.png',
    'assets/Trinajst.png',
  ];

  @override
  void initState() {
    super.initState();
    userID = UserPreferences.getUserID();
    fetchLectureProgress();
  }

  void fetchLectureProgress() async {
    final response = await http.get(Uri.parse('${API.getLectureProgress}?user_id=$userID'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        lectureProgress = data['lecture_progress'] ?? 0;
        userPoints = data['points'] ?? 0;

        for (int i = 0; i < lectureProgress!; i++) {
          _isLectureUnlocked[i] = true;
        }
      });
    } else {
      print('Failed to fetch lecture progress');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          fetchLectureProgress();
        },
        child: Padding(
          padding: const EdgeInsets.only(top: 70.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Number of columns in the grid
              childAspectRatio: 0.8, // Aspect ratio to fit icon and label
              crossAxisSpacing: 5.0, // Decrease spacing between columns
              mainAxisSpacing: 5.0, // Decrease spacing between rows
            ),
            itemCount: 13, // Number of lectures
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: _isLectureUnlocked[index]
                    ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizScreen(
                        lectureId: index + 1,
                        onComplete: fetchLectureProgress,
                      ),
                    ),
                  );
                }
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _isLectureUnlocked[index]
                            ? Theme.of(context).primaryColor
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                     child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                       borderRadius: BorderRadius.circular(20.0),
                       child: Image.asset(
                  lectureIcons[index], // Use the corresponding icon
                     width: 100, // Icon width
                     height: 100, // Icon height
                        ),
                      ),
                     ),
                   ),

                    SizedBox(height: 6.0),
                    Text(
                      'Predavanje ${index + 1}',
                      style: TextStyle(
                        color: _isLectureUnlocked[index]
                            ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black54)
                            : Colors.grey,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
