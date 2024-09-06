import 'package:diploma/api_connection/api_connection.dart';
import 'package:diploma/theme/theme.dart';
import 'package:diploma/users/authentication/weclome_page.dart';
import 'package:diploma/widgets/my_password_field.dart';
import 'package:diploma/widgets/my_text_button.dart';
import 'package:diploma/widgets/my_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import "package:http/http.dart" as http;
import 'dart:convert';
import "./login_screen.dart";

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}class _SignUpScreenState extends State<SignUpScreen> {
  bool passwordVisibility = true;


  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {

    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _trySubmitForm() async {
    final isValid = _formKey.currentState?.validate();
    if (isValid == true) {
      FocusScope.of(context).unfocus();

      // Retrieve form data
      final _username = _usernameController.text.trim();
      final _email = _emailController.text.trim();
      final _password = _passwordController.text.trim();

      final url = Uri.parse(API.signUp);

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'username': _username,
            'password': _password,
            'email': _email,
          }),
        );
        print('Raw response body: ${response.body}');
        if (response.statusCode == 200) {
          final responseBody = json.decode(response.body);

          if (responseBody['status'] == 'success') {
            print('Signed up successfully.');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => Login()),
            );
          } else {
            _showErrorDialog(responseBody['message']);
            print('Failed to sign up.');
          }
        } else {
          _showErrorDialog('Server error: ${response.statusCode}');
          print('Server error: ${response.statusCode}');
        }
      } catch (error) {
        _showErrorDialog('Could not connect to the server. Please try again later.');
        print('Error: $error');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('An error occurred'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              CupertinoPageRoute(
                builder: (context) => WelcomePage(),
              ),
            );
          },
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
        ),
      ),
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Registriraj se",
                              style: kHeadline,
                            ),
                            Text(
                              "Naredi nov račun.",
                              style: kBodyText2,
                            ),
                            SizedBox(
                              height: 50,
                            ),
                            // Username field
                            TextFormField(
                              controller: _usernameController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Uporabniško ime',
                                hintStyle: TextStyle(color: Colors.white),
                                fillColor: kTextFieldFill,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              keyboardType: TextInputType.name,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vnesite uporabniško ime';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            // Email field
                            TextFormField(
                              controller: _emailController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle: TextStyle(color: Colors.white),
                                fillColor: kTextFieldFill,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty || !value.contains('@')) {
                                  return 'Vnesite veljaven email';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 10),
                            // Password field
                            MyPasswordField(
                              isPasswordVisible: passwordVisibility,
                              onTap: () {
                                setState(() {
                                  passwordVisibility = !passwordVisibility;
                                });
                              },
                              fillColor: kTextFieldFill,
                              controller: _passwordController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vnesite geslo';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Si že registriran? ",
                            style: kBodyText,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Login(), // Navigate to Login screen
                                ),
                              );
                            },
                            child: Text(
                              "Prijavi se",
                              style: kBodyText.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      MyTextButton(
                        buttonName: 'Registriraj se',
                        onTap: _trySubmitForm, // Form submission
                        bgColor: Colors.white,
                        textColor: Colors.black87,
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

