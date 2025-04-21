import 'package:escala_mobile/models/user_model.dart';
import 'package:escala_mobile/screens/home/home_screen.dart';
import 'package:escala_mobile/screens/login/login_screen.dart';
import 'package:escala_mobile/screens/permutas/permuta_screen.dart';
import 'package:escala_mobile/services/ApiClient.dart';
import 'package:escala_mobile/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Notificação em background recebida: ${message.notification?.title}");

  // Exibir notificação local
  await NotificationService.showNotification(
    message.notification?.title ?? "Nova Permuta",
    message.notification?.body ?? "Você recebeu uma nova solicitação de permuta.",
    0,
  );

  // Incrementar contador no SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  int currentCount = prefs.getInt('notificationCount') ?? 0;
  await prefs.setInt('notificationCount', currentCount + 1);
  print("🔔 Contador em background atualizado: ${currentCount + 1}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('pt_BR', null);
  await NotificationService.init();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final userModel = UserModel();
  bool isLoggedIn = await userModel.loadUserFromToken();

  runApp(
    ChangeNotifierProvider(
      create: (_) => userModel,
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
  }

  void _setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    // Carregar contador inicial do SharedPreferences
    final userModel = Provider.of<UserModel>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    int initialCount = prefs.getInt('notificationCount') ?? 0;
    if (initialCount > 0) {
      userModel.setInitialNotificationCount(initialCount);
    }

    // Notificações em foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Notificação em foreground recebida: ${message.notification?.title}");
      userModel.incrementNotificationCount();
      NotificationService.showNotification(
        message.notification?.title ?? "Nova Permuta",
        message.notification?.body ?? "Você recebeu uma nova solicitação de permuta.",
        0,
      );
    });

    // Quando o app é aberto a partir de uma notificação
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("📩 App aberto por notificação: ${message.notification?.title}");
      userModel.incrementNotificationCount();
      Navigator.pushNamed(context, '/permutas');
    });

    // Enviar FCM Token ao backend
    String? fcmToken = await messaging.getToken();
    if (fcmToken != null) {
      print("🔑 FCM Token: $fcmToken");
      await _sendFcmTokenToBackend(fcmToken);
    }

    // Atualizar FCM Token se ele mudar
    messaging.onTokenRefresh.listen((newToken) {
      print("🔑 FCM Token atualizado: $newToken");
      _sendFcmTokenToBackend(newToken);
    });
  }

Future<void> _sendFcmTokenToBackend(String fcmToken) async {
    final userModel = Provider.of<UserModel>(context, listen: false);
    if (userModel.idFuncionario.isNotEmpty) {
        try {
            final response = await ApiClient.post(
                "/login/updateFcmToken",
                {"idFuncionario": userModel.idFuncionario, "fcmToken": fcmToken},
            );
            print("✅ FCM Token enviado: ${response["statusCode"]} - ${response["body"]}");
        } catch (e) {
            print("❌ Erro ao enviar FCM Token: $e");
        }
    }
}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Escala Mobile',
      theme: ThemeData(primarySwatch: Colors.blue),
      supportedLocales: const [Locale('pt', 'BR')],
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: widget.isLoggedIn ? const HomeScreen() : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/permutas': (context) => const PermutaScreen(),
      },
    );
  }
}