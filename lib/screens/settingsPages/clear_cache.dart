import 'package:flutter/material.dart';

class ClearCache extends StatelessWidget {
  const ClearCache({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Clear Cache")),
      body: const Center(child: Text("Clear Cache Page")),
    );
  }
}
