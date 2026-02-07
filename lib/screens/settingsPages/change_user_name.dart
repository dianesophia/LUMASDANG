import 'package:flutter/material.dart';

class ChangeUserName extends StatelessWidget {
  const ChangeUserName({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change User Name")),
      body: const Center(child: Text("Change User Name Page")),
    );
  }
}
