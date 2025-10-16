import 'package:flutter/material.dart';

class VideoPlaybackPage extends StatelessWidget {
  const VideoPlaybackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Video Playback")),
      body: const Center(
        child: Text("Here you will add recorded footage review."),
      ),
    );
  }
}
