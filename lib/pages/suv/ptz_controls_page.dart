import 'package:flutter/material.dart';

class PTZControlsPage extends StatelessWidget {
  const PTZControlsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PTZ Controls")),
      body: const Center(
        child: Text("Here you will add Pan-Tilt-Zoom controls."),
      ),
    );
  }
}
