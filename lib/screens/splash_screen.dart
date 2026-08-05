import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ultrixplay/home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3),
            ()=>Navigator.pushReplacement(context,
            MaterialPageRoute(builder:
                (context) => HomePage()
            )
        )
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Container(
          decoration: const BoxDecoration(
            // gradient: LinearGradient(
            //   begin: Alignment.bottomRight,
            //   end: Alignment.topLeft,
            //   colors: [
            //     Color(0xFF000033),
            //     Color(0xFF330099),
            //     Color(0xFF4D4DFF),
            //   ],
            //   stops: [0.0, 0.5, 1.0],
            // ),
            color: Color(0xFF05044A),
          ),
          child: Center(
              child: Image.asset('assets/images/up_icon.png',height: 300,)
          ),
        ),
      ),
    );
  }
}
