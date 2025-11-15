import 'dart:io';
import 'package:bot_toast/bot_toast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tochegando_driver_app/core/utils/translate.dart';

import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../Auth/login_screen.dart';

class AllowLocationScreen extends StatefulWidget {
  const AllowLocationScreen({super.key});

  @override
  State<AllowLocationScreen> createState() => _AllowLocationScreenState();
}

class _AllowLocationScreenState extends State<AllowLocationScreen> {
  bool isLocationDenied = false;
  bool isOverlayDenied = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (Platform.isIOS) {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission != LocationPermission.always) {
        setState(() => isLocationDenied = true);

      } else {
        _goToNextScreen();
      }
    } else {
      final isLocationGranted = await Permission.locationWhenInUse.isGranted;
      final isOverlayGranted = await Permission.systemAlertWindow.isGranted;

      if (isLocationGranted && isOverlayGranted) {
        _goToNextScreen();
      } else {
        setState(() {
          isLocationDenied = !isLocationGranted;
          isOverlayDenied = !isOverlayGranted;
        });

      }
    }
  }
  Future<void> _requestPermissions() async {
    bool blocked = false;

    if (Platform.isIOS) {
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        blocked = true; // Just for tracking
      }

      // iOS me chahe blocked ho ya na ho, hamesha next screen
      _goToNextScreen();
    } else {
      // Android Flow
      final overlayStatus = await Permission.systemAlertWindow.status;
      if (overlayStatus.isDenied) {
        final result = await Permission.systemAlertWindow.request();
        if (result.isPermanentlyDenied) {
          // ignore: use_build_context_synchronously
          BotToast.showText(text: "Permissão de sobreposição negada. Ative nas configurações.".translate(context));
          blocked = true;
        }
      }

      final locationStatus = await Permission.locationWhenInUse.status;
      if (locationStatus.isDenied) {
        final result = await Permission.locationWhenInUse.request();
        if (result.isPermanentlyDenied) {
          // ignore: use_build_context_synchronously
          BotToast.showText(text: "Permissão de localização negada. Ative nas configurações.".translate(context));
          blocked = true;
        }
      }

      if (blocked) {
        await openAppSettings();
      } else {
        _checkPermissions();
      }
    }
  }

  void _goToNextScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {



    final permissionText = Platform.isIOS
        ? "Precisamos da sua localização mesmo quando o app não estiver aberto para garantir o rastreamento preciso das corridas.\n\nQuando o iOS solicitar, escolha a opção que permite acesso à localização o tempo todo. Isso ajudará seu motorista a encontrá-lo mais rapidamente, garantirá segurança e melhorará a precisão da rota."
        : "Para atendê-lo melhor, precisamos de:\n\n1. *Acesso à Localização* – para rastreamento em tempo real mesmo em segundo plano.\n2. *Permissão de Sobreposição* – para mostrar atualizações da corrida enquanto você usa outros apps.\n\nIsso ajuda seu motorista a chegar até você rapidamente e mantém sua viagem contínua.";

    return Scaffold(
      backgroundColor: whiteColor,
      body: Stack(
        children: [
          Positioned(
              left: 0,
              top: 0,
              child: SvgPicture.asset("assets/images/EllipseTop.svg",)),
          Positioned(
              left: 0,
              top: 0,
              child: SvgPicture.asset("assets/images/topEllipse.svg",)),

          Center(
            child: Column(
              children: [
                const SizedBox(height: 130),
                Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(50),
                      child: Image.asset('assets/images/permission.png',
                          height: 120),
                    )),
                const SizedBox(height: 30),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Text(
                      permissionText.translate(context),
                      textAlign: TextAlign.center,
                      style: heading3Grey1(context).copyWith(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CustomsButtons(
                textColor: blackColor,
                text: "Continuar",
                backgroundColor: themeColor,
                onPressed: _requestPermissions,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
Future<bool> checkAndRequestAlwaysLocationPermission(BuildContext context) async {
  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.always) return true;

   
  bool goToSettings = await Future.delayed(Duration.zero, () {
    return showDialog<bool>(
      // ignore: use_build_context_synchronously
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: notifires.getbgcolor,
        title: Row(
          children: [
            const Icon(Icons.my_location, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Text("Ativar Localização em Segundo Plano".translate(context), style: heading2Grey1(context)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Permitir a localização em segundo plano nos ajuda a mostrar solicitações de corrida próximas a você, mesmo quando o aplicativo não estiver aberto. Você pode escolher 'Sempre' na próxima tela, se desejar este recurso.".translate(context),
              style: regular2(context),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.looks_one, size: 20, color: Colors.green),
                const SizedBox(width: 6),
                Expanded(
                  child: Text("Selecione 'Continuar' para revisar as configurações de localização.".translate(context), style: regular(context)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.looks_two, size: 20, color: Colors.green),
                const SizedBox(width: 6),
                Expanded(
                  child: Text("Em Acesso à Localização, você pode escolher 'Sempre' para permanecer conectado.".translate(context), style: regular(context)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Agora não".translate(context), style: heading3Grey1(context)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context, true);
              openAppSettings();
            },
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: Text("Continuar".translate(context), style: heading3Grey1(context).copyWith(color: blackColor)),
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }) ?? false;

  if (goToSettings) {
    permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always;
  }
  return false;
}