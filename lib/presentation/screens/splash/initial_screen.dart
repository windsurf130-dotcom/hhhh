import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:ride_on_driver/presentation/screens/Splash/splash_screen.dart';
import 'package:ride_on_driver/presentation/screens/bottom_bar/home_main.dart';

import '../../../core/extensions/workspace.dart';
import '../../../core/utils/theme/project_color.dart';
import '../Onboarding/on_boarding_screen.dart';
import '../Search/ride_screen.dart';

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  @override
  void initState() {
    super.initState();
    setScreen(context);
  }

  Future<void> setScreen(BuildContext context) async {
    var box = Hive.box('appBox');

    final duration = Duration(
      seconds: box.get('Firstuser', defaultValue: null) == null ? 4 : 0,
    );

    Timer(duration, () {
      if (box.get('Firstuser', defaultValue: false) != true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const Onboardingscreen(),
          ),
        );
      } else {
        String? rideId = box.get('ride_id');

        if (rideId == null || rideId.isEmpty) {
          getUserDataLocallyToHandleTheState(context, isHomePage: false);
        } else {
          getUserDataLocallyToHandleTheState(context, isHomePage: true);
          getCurrency(context);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RideScreens(
                rideId: rideId,
                fromInitialPage: true,
              ),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    notifires = Provider.of<ColorNotifires>(context, listen: true);
    return Scaffold(
        backgroundColor: notifires.getbgcolor, body: const SplashScreen());
  }
}
