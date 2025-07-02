import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // Configurar callback para quando o usuário interage com a notificação
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        //print("📩 Notificação clicada: ${response.payload}");
        // Aqui você pode adicionar lógica para navegação ao clicar na notificação
      },
    );

    // Criar canal de notificação para Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'permuta_channel', // ID do canal
      'Permutas', // Nome do canal
      description: 'Notificações de permutas',
      importance: Importance.max,
    );
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> showNotification(String title, String body, int id) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'permuta_channel',
      'Permutas',
      channelDescription: 'Notificações de permutas',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(id, title, body, notificationDetails);
  }

  static Future<void> updateBadge(int count) async {
    await showNotification(
      'Permutas Pendentes',
      'Você tem $count permutas pendentes.',
      0, // ID fixo para sobrescrever notificações anteriores
    );
  }
}