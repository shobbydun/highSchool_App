import 'package:flutter/material.dart';

class MyTextfield extends StatelessWidget {
  final controller;
  final String hintText;
  final bool obscureText;

  const MyTextfield({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: TextField(
        style: const TextStyle(color: Colors.black),
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green),
          ),
          fillColor: Colors.grey[500],
          filled: true,
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
