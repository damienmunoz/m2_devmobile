// ignore_for_file: use_build_context_synchronously, avoid_print, prefer_const_constructors, sort_child_properties_last, prefer_interpolation_to_compose_strings, library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'bottom_bar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController(text: '');
  final TextEditingController _passwordController = TextEditingController(text: '');
  bool _loginError = false;

  Future<void> _login(BuildContext context) async {
    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();
      if (email.isNotEmpty && password.isNotEmpty) {
        final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email,password: password);
        final String userId = userCredential.user!.uid;
        final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
        final userDocSnapshot = await userDoc.get();

        if (!userDocSnapshot.exists) {
          await userDoc.set({
            'email': email,
          });
        }

        final cartCollection = userDoc.collection('cart');
        final cartSnapshot = await cartCollection.get();

        if (cartSnapshot.docs.isEmpty) {
          await cartCollection.add({});
        }

        Fluttertoast.showToast(
          msg: "Bienvenue "+ email +" !",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 3,
          textColor: Colors.white,
          fontSize: 16.0,
          webPosition: "center",
          webBgColor:"#006400",
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BottomBar()),
        );
      } else {
        print('Login and password cannot be empty');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Erreur de connexion",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 3,
        textColor: Colors.white,
        fontSize: 16.0,
        webPosition: "center",
        webBgColor:"#8B0000",
      );
      print('Error logging in: $e');
      setState(() {
        _loginError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Application Miage',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Arial',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Login',
                  labelStyle: const TextStyle(color: Colors.black),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  prefixIcon: const Icon(Icons.email, color: Colors.black),
                ),
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 12.0),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.black),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  prefixIcon: const Icon(Icons.lock, color: Colors.black),
                ),
                style: const TextStyle(color: Colors.black),
                obscureText: true,
              ),
              if (_loginError)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Invalid login or password',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: () => _login(context),
                child: const Text(
                  'Se connecter',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
