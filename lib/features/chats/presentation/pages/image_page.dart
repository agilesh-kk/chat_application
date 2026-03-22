import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FullScreenImagePage extends StatefulWidget {
  final Uint8List bytes;
  final String tag;

  const FullScreenImagePage({
    super.key,
    required this.bytes,
    required this.tag,
  });

  @override
  State<FullScreenImagePage> createState() =>
      _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {
  bool showUI = false;

  @override
  void initState() {
    super.initState();
    _hideSystemUI(); 
  }

  void _hideSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, 
      statusBarIconBrightness: Brightness.light, 
      statusBarBrightness: Brightness.light,
    ),
  );
  }

  void _showSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.black, 
      statusBarIconBrightness: Brightness.light, 
      statusBarBrightness: Brightness.dark, 
    ),
  );
  }

  void toggleUI() {
    setState(() {
      showUI = !showUI;
    });
  }

  @override
  void dispose() {
    _showSystemUI(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: toggleUI,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 1,
              maxScale: 10,
              child: Center(
                child: Hero(
                  tag: widget.tag,
                  child: SizedBox(
                    width: MediaQuery.sizeOf(context).width,
                    height: MediaQuery.sizeOf(context).height,
                    child: Image.memory(
                      widget.bytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            if (showUI)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  color: Colors.black,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Image",
                        style: TextStyle(color: Colors.white,fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}