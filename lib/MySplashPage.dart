import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:eyes_app/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MySplashPage extends StatefulWidget {
  const MySplashPage({super.key});

  @override
  State<MySplashPage> createState() => _MySplashPageState();
}

class _MySplashPageState extends State<MySplashPage> {
  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterSplashScreen(
      duration: const Duration(milliseconds: 3000),
      nextScreen: const HomePage(),
      backgroundColor: Colors.white,
      splashScreenBody: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 100,
            ),
            const Spacer(),
            SizedBox(
              width: 200,
              child: Image.asset('assets/images/Eyes4U.png'),
            ),
            const Spacer(),
            const SizedBox(
              height: 100,
            ),
          ],
        ),
      ),
    );
  }
}
