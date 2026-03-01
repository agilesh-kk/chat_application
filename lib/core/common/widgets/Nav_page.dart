import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class NavigationPage extends StatefulWidget {
  final List<dynamic> pages;

  NavigationPage({super.key, required this.pages});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.pages[index],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.chat),label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.chat),label: "Status"),
          BottomNavigationBarItem(icon: Icon(Icons.person),label: "Profile")
        ],
        currentIndex: 0,
        onTap: (v){
          setState((){
            index = v;
          });
        },
      ),
    );
  }
}