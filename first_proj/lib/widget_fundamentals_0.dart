import 'package:flutter/material.dart';
import 'dart:developer' as developer;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp( // Root widget

      home: Scaffold(

        appBar: AppBar(
          title: const Text('My Home Page'),
        ),

        body: Center(
          child: Builder(
            builder: (context) {
              return Column(
                children: [
                  const Text('Hello, World!'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      developer.log('Click!') ;
                    },
                    child: const Text('A button'),
                  ),
                ],
              );
            },
          ),
        ),

      ),
    );
  }
}