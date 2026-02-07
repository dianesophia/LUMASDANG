import 'package:flutter/material.dart';

class CustomizeAppearance extends StatelessWidget {
  const CustomizeAppearance({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customize Appearance")),
      body: const Center(child: Text("Customize Appearance Page")),
    );
  }
}
