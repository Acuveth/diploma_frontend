import 'package:diploma/users/authentication/weclome_page.dart';
import 'package:flutter/material.dart';
import 'pages/lectures_page.dart';
import 'pages/profile_page.dart';
import 'pages/chat_predavanja.dart';
import 'context/context.dart';
import 'theme/theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:diploma/api_connection/api_connection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserPreferences.init();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = true;
  String? profilePicture;

  @override
  void initState() {
    super.initState();
    // Ensure dark mode preference is loaded at startup
    isDarkMode = UserPreferences.isDarkMode();
    _fetchProfilePicture();
  }

  Future<void> _fetchProfilePicture() async {
    int? userID = UserPreferences.getUserID();
    if (userID != null) {
      final response = await http.get(Uri.parse('${API.getProfile}?id=$userID'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          profilePicture = data['profile_picture'];
        });
      }
    }
  }

  void toggleTheme(bool isDarkMode) {
    setState(() {
      this.isDarkMode = isDarkMode;
      UserPreferences.setDarkMode(isDarkMode); // Save the theme preference
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is logged in and show appropriate screen
    bool isLoggedIn = UserPreferences.isLoggedIn();
    Widget home = isLoggedIn
        ? MyHomePage(
      title: 'Diploma',
      profilePicture: profilePicture,
      onThemeChanged: toggleTheme,
      isDarkMode: isDarkMode,  // Pass the theme state
    )
        : WelcomePage();

    return MaterialApp(
      theme: isDarkMode ? darkTheme : lightTheme, // Apply the correct theme
      home: home,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    this.profilePicture,
    required this.onThemeChanged,
    required this.isDarkMode,
  });

  final String title;
  final String? profilePicture;
  final ValueChanged<bool> onThemeChanged;
  final bool isDarkMode;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  String? currentProfilePicture;

  @override
  void initState() {
    super.initState();
    currentProfilePicture = widget.profilePicture;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onProfilePictureChanged(String newPicture) {
    setState(() {
      currentProfilePicture = newPicture;
    });
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return ChatScreen();
      case 1:
        return const LecturesPage();
      case 2:
        return ProfilePage(
          onThemeChanged: widget.onThemeChanged,
          onProfilePictureChanged: _onProfilePictureChanged,
          isDarkMode: widget.isDarkMode,
        );
      default:
        return const Center(child: Text('Unknown'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_rounded),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: currentProfilePicture != null
                ? CircleAvatar(
              radius: 15,
              backgroundImage: AssetImage(currentProfilePicture!),
            )
                : Icon(Icons.account_circle),
            label: '',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        iconSize: 35.0,
      ),
    );
  }
}
