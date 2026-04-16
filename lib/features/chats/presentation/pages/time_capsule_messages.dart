import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TimeCapsuleMessages extends StatefulWidget {
  const TimeCapsuleMessages({super.key});

  @override
  State<TimeCapsuleMessages> createState() => _TimeCapsuleMessagesState();
}

class _TimeCapsuleMessagesState extends State<TimeCapsuleMessages> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Time capsule messages"),
      ),
      
    );
  }
}