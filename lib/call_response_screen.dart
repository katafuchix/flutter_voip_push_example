import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class CallResponseScreen extends StatelessWidget {
  final AudioPlayer audioPlayer = AudioPlayer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Audio Call')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                //await audioPlayer.play('https://example.com/audio.mp3');
              },
              child: Text('Play Audio'),
            ),
            ElevatedButton(
              onPressed: () async {
                await audioPlayer.stop();
              },
              child: Text('Stop Audio'),
            ),
          ],
        ),
      ),
    );
  }
}

void showAudioPlayerDialog(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    pageBuilder: (context, animation1, animation2) {
      return CallResponseScreen();
    },
  );
}
