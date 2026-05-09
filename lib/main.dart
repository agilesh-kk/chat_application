import 'dart:convert';


import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/achievement/presentation/bloc/achievement_bloc.dart';
import 'package:chat_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_application/features/auth/presentation/pages/auth_gate.dart';
import 'package:chat_application/features/chats/presentation/bloc/chat/chat_bloc.dart';
import 'package:chat_application/features/chats/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:chat_application/features/chats/presentation/bloc/search/search_bloc.dart';
import 'package:chat_application/features/chats/presentation/bloc/time_capsule/time_capsule_bloc.dart';
import 'package:chat_application/features/chats/presentation/pages/chat_page.dart';
import 'package:chat_application/features/friends/presentation/friends_cubit.dart';
import 'package:chat_application/features/profile/presentation/bloc/bio/bio_bloc.dart';
import 'package:chat_application/features/profile/presentation/bloc/profile_picture/profilePic_bloc.dart';
import 'package:chat_application/features/status/presentation/bloc/status/status_bloc.dart';
import 'package:chat_application/features/status/presentation/bloc/status_view/statusview_bloc.dart';
import 'package:chat_application/features/timeline/presentation/bloc/personal_time_line/personal_timeline_bloc.dart';
import 'package:chat_application/features/timeline/presentation/bloc/time_line/timeline_bloc.dart';
import 'package:chat_application/firebase_options.dart';
import 'package:chat_application/init_dependencies.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
const int _groupSummaryId = -1001;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp();

  _showNotification(message.data);
}

void _showNotification(Map<String, dynamic> data) {
  final chatId = data['chat_id'] as String? ?? '';
  final senderName = data['sender_name'] as String? ?? '';
  final messageText = data['message'] as String? ?? '';

  if (chatId.isEmpty) return;

  flutterLocalNotificationsPlugin.show(
    chatId.hashCode,
    senderName,
    messageText,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'chat_messages',
        'Chat Messages',
        channelDescription: 'New chat message notifications',
        importance: Importance.high,
        priority: Priority.high,
        color: AppPallete.primaryOrange,
        groupKey: 'chat_app_group',
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        threadIdentifier: chatId,
      ),
    ),
    payload: jsonEncode(data),
  );

  flutterLocalNotificationsPlugin.show(
    _groupSummaryId,
    'Chat App',
    null,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'chat_messages',
        'Chat Messages',
        channelDescription: 'New chat message notifications',
        importance: Importance.high,
        priority: Priority.high,
        groupKey: 'chat_app_group',
        setAsGroupSummary: true,
        icon: '@mipmap/ic_launcher',
      ),
    ),
  );
}

void navigateFromNotification(Map<String, dynamic> data) {
  final chatId = data['chat_id'] as String?;
  final senderId = data['sender_id'] as String?;
  final senderName = data['sender_name'] as String?;

  if (chatId == null || senderId == null || senderName == null) return;

  final appUserState = serviceLocator<AppUserCubit>().state;
  if (appUserState is! AppUserIsSignedin) return;
  final currentUserId = appUserState.user.id;

  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => ChatPage(
        convoId: chatId,
        currentUserId: currentUserId,
        receiverId: senderId,
        receiverName: senderName,
      ),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseMessaging.instance.requestPermission();
  flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler
  );

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: androidSettings, iOS: iosSettings),
    onDidReceiveNotificationResponse: (response) {
      final data = response.payload != null ? jsonDecode(response.payload!) as Map<String, dynamic> : null;
      if (data != null) navigateFromNotification(data);
    },
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannelGroup(
        AndroidNotificationChannelGroup(
          'chat_app_group',
          'Chat App',
        ),
      );

  final channel = AndroidNotificationChannel(
    'chat_messages',
    'Chat Messages',
    description: 'New chat message notifications',
    importance: Importance.high,
    groupId: 'chat_app_group',
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await initDependencies();
  runApp(
    MultiBlocProvider(
      providers: [
        //app user signed in cubit
        BlocProvider(
          create: (_) => serviceLocator<AppUserCubit>(), //loads the app_user_cubit contents from the dependency file
        ),

        //user friends cubit
        BlocProvider(
          create: (context) => serviceLocator<FriendsCubit>(),
        ),

        //authentication bloc
        BlocProvider(
          create: (_) => serviceLocator<AuthBloc>()
          ..add(AuthCheckRequested()),
        ),

        //chat bloc
        BlocProvider(
          create: (_) => serviceLocator<ChatBloc>(), 
        ),
        BlocProvider(
          create: (_)=> serviceLocator<TimeCapsuleBloc>()
        ),
        BlocProvider(
          create: (_) => serviceLocator<ConversationBloc>(), 
        ),
        BlocProvider(
          create: (_) => serviceLocator<SearchBloc>(),
        ),

        //status bloc
        BlocProvider(
          create: (_) => serviceLocator<StatusBloc>(),
        ),
        //status view bloc
        BlocProvider(
          create: (_) => serviceLocator<StatusviewBloc>(),
        ),

        //profile blocs
        BlocProvider(
          create: (_) => serviceLocator<ProfilePicBloc> ()
        ),
        BlocProvider(
          create: (_) => serviceLocator<BioBloc>(),
        ),

        //timeline bloc
        BlocProvider(
          create: (_) => serviceLocator<TimelineBloc>(),
        ),
        BlocProvider(
          create: (_) => serviceLocator<PersonalTimelineBloc>(),
        ),

        //achivement bloc
        BlocProvider(
          create: (_) => serviceLocator<AchievementBloc>(),
        )
      ],
      child: MyApp(),
    ),
  );
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _handleInitialMessage();
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      navigateFromNotification(msg.data);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _handleInitialMessage() async {
    final msg = await FirebaseMessaging.instance.getInitialMessage();
    if (msg != null && mounted) {
      navigateFromNotification(msg.data);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cubit = serviceLocator<AppUserCubit>();
    if (state == AppLifecycleState.resumed) {
      cubit.setOnline(true);
    } else if (state == AppLifecycleState.paused) {
      cubit.setOnline(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Color(0xFF0D0D0D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFFFF6B35),
          brightness: Brightness.dark,
        ),
      ),
      home: AuthGate(),
    );
  }
}
