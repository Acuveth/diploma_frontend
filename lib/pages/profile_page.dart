import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:diploma/api_connection/api_connection.dart';
import '../context/context.dart';
import '../users/authentication/login_screen.dart';

class ProfilePage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<String> onProfilePictureChanged;
  final bool isDarkMode;

  const ProfilePage({
    Key? key,
    required this.onThemeChanged,
    required this.onProfilePictureChanged,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>> profileData;
  late Future<List<Map<String, dynamic>>> nonProfessorUsers;
  bool isDarkMode = false;

  final List<String> profilePictures = [
    'assets/cat.png',
    'assets/elephant.png',
    'assets/image.jpg',
    'assets/leo.jpg',
    'assets/monkey.png'
  ];

  String? selectedPicture;

  @override
  void initState() {
    super.initState();
    profileData = getProfileData();
    nonProfessorUsers = getLeaderboard();
    isDarkMode = widget.isDarkMode;
  }

  Future<Map<String, dynamic>> getProfileData() async {
    int? userID = UserPreferences.getUserID();
   // print('User ID: $userID');
    if (userID == null) {
      throw Exception('User ID is null');
    }

    final response = await http.get(Uri.parse('${API.getProfile}?id=$userID'));
    //print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      selectedPicture = data['profile_picture'];
      return data;
    } else {
      throw Exception('Failed to load profile data');
    }
  }

  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final response = await http.get(Uri.parse(API.getLeaderdoard));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load non-professor users');
    }
  }

  void _logout() async {
    await UserPreferences.setLoggedIn(false);
    await UserPreferences.setUserID(null);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Login()),
          (route) => false,
    );
  }

  void _selectPicture(String picture) {
    setState(() {
      selectedPicture = picture;
    });
    _saveSelectedPicture(picture);
    widget.onProfilePictureChanged(picture);
  }

  Future<void> _saveSelectedPicture(String picture) async {
    int? userID = UserPreferences.getUserID();
    if (userID == null) {
      throw Exception('User ID is null');
    }

    final response = await http.post(
      Uri.parse('${API.updateProfilePicture}'),
      body: {'user_id': userID.toString(), 'profile_picture': picture},
    );


   // print("Response status: ${response.statusCode}");
   // print("Response body: ${response.body}");

    if (response.statusCode == 200) {

      setState(() {
        nonProfessorUsers = getLeaderboard();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile picture changed successfully.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save profile picture.")),
      );
    }
  }

  Future<void> _activateLiveQuestions() async {
    final response = await http.post(Uri.parse(API.activateLiveQuestions));
   // print("Clicked");
    if (response.statusCode == 200) {
      print("status code 200");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Live questions activated successfully!")),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to activate live questions")),
        );
      }
    }
  }

  void _openPictureSelection() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Izberi profilno sliko'),
          content: Container(
            width: double.maxFinite,
            height: 300.0,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: profilePictures.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final picture = profilePictures[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _selectPicture(picture);
                  },
                  child: CircleAvatar(
                    backgroundImage: AssetImage(picture),
                  ),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
      widget.onThemeChanged(isDarkMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Row(
            children: [
              IconButton(
                icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: _toggleDarkMode,
              ),
              SizedBox(width: 10),
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: _logout,
              ),
              SizedBox(width: 30),
            ],
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: profileData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {

            print("Error: ${snapshot.error}");

            return Center(child: Text("An error occurred. Please try again later."));
          } else if (snapshot.hasData) {
            final data = snapshot.data!;
            final userName = data['username'] ?? 'N/A';
            final userPoints = data['points']?.toString() ?? '0';
            final userFires = data['fires']?.toString() ?? '0';
            final isProfessor = data['is_professor'] == 1;

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _openPictureSelection,
                    child: CircleAvatar(
                      radius: 80,
                      backgroundImage: selectedPicture != null
                          ? AssetImage(selectedPicture!)
                          : AssetImage('assets/image.jpg'),
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        userPoints,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Row(
                        children: [
                          Icon(Icons.whatshot, color: Colors.orange),
                          const SizedBox(width: 5),
                          Text(
                            userFires,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text(
                      'Leaderboard:',
                      style: Theme.of(context).textTheme.headline6?.copyWith(
                        fontSize: 32,
                      ),
                    ),
                  ),
                  if (isProfessor)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: ElevatedButton(
                        onPressed: _activateLiveQuestions,
                        child: Text("Activate Live Questions"),
                      ),
                    ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: nonProfessorUsers,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text("Failed to load users."));
                      } else if (snapshot.hasData) {
                        final users = snapshot.data!;
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            String trophyAsset;
                            if (index == 0) {
                              trophyAsset = 'assets/gold_trophy.png';
                            } else if (index == 1) {
                              trophyAsset = 'assets/silver_trophy.png';
                            } else if (index == 2) {
                              trophyAsset = 'assets/bronze_trophy.png';
                            } else {
                              trophyAsset = '';
                            }
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 80.0, vertical: 5.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 15,
                                            backgroundImage: user['profile_picture'] != null
                                                ? AssetImage(user['profile_picture'])
                                                : AssetImage('assets/image.jpg'),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            user['username'],
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          if (trophyAsset.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(right: 10.0),
                                              child: Image.asset(
                                                trophyAsset,
                                                width: 24,
                                                height: 24,
                                              ),
                                            ),
                                          Text(
                                            user['points']?.toString() ?? '0',
                                            style: const TextStyle(
                                              fontSize: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Icon(Icons.whatshot, color: Colors.orange),
                                          const SizedBox(width: 5),
                                          Text(
                                            user['fires']?.toString() ?? '0',
                                            style: const TextStyle(
                                              fontSize: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Add spacing between users
                                const SizedBox(height: 5),
                              ],
                            );
                          },
                        );
                      } else {
                        return Center(child: Text("No users available"));
                      }
                    },
                  )
                ],
              ),
            );
          } else {
            return Center(child: Text("No data available"));
          }
        },
      ),
    );
  }
}
