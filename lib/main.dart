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

import 'notification_storage.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
const int _groupSummaryId = 2001;
final Map<String, Person> _personCache = {};

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp();
  await _showNotification(message.data);
}

Future<void> _showNotification(Map<String, dynamic> data) async {
  final chatId = data['chat_id'] as String? ?? '';
  final senderName = data['sender_name'] as String? ?? '';
  final messageText = data['message'] as String? ?? '';
  final senderId = data['sender_id'] as String? ?? '';

  if (chatId.isEmpty) return;

  final List<Map<String, dynamic>> messages = await loadChatMessages(chatId);
  messages.add({
    'sender_name': senderName,
    'sender_id': senderId,
    'text': messageText,
    'time': DateTime.now().toIso8601String(),
  });
  if (messages.length > 5) {
    messages.removeAt(0);
  }
  await saveChatMessages(chatId, messages);

  final collapsedTitle = "sdsdfsdfsdf";
  final collapsedBody = "1sfsfsdfsdf";

  _personCache[senderId] ??= Person(name: senderName, key: senderId);
  for (final m in messages) {
    final sid = m['sender_id'] as String;
    _personCache[sid] ??= Person(name: m['sender_name'] as String, key: sid);
  }

  final messagingStyle = MessagingStyleInformation(
    _personCache[senderId]!,
    conversationTitle: senderName,
    messages: messages.map((m) => Message(
      m['text'] ?? '',
      DateTime.parse(m['time'] as String),
      _personCache[m['sender_id'] as String]!,
    )).toList(),
    groupConversation: true,
  );

  await flutterLocalNotificationsPlugin.show(
    chatId.hashCode,
    collapsedTitle,
    collapsedBody,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'chat_messages',
        'Chat Messages',
        channelDescription: 'New chat message notifications',
        importance: Importance.high,
        priority: Priority.high,
        //color: AppPallete.primaryOrange,
        groupKey: 'chat_app_group',
        icon: '@drawable/ic_stat_notify',
        onlyAlertOnce: true,
        category: AndroidNotificationCategory.message,
        tag: chatId,
        styleInformation: messagingStyle,
      ),
      iOS: DarwinNotificationDetails(
        threadIdentifier: chatId,
      ),
    ),
    payload: jsonEncode(data),
  );

  final activeChats = await loadActiveChats();
  if (!activeChats.contains(chatId)) {
    activeChats.add(chatId);
    await saveActiveChats(activeChats);
  }

  int totalMessages = 0;
  for (final cid in activeChats) {
    final msgs = await loadChatMessages(cid);
    totalMessages += msgs.length;
  }

  if (activeChats.length > 1) {
    await flutterLocalNotificationsPlugin.show(
      _groupSummaryId,
      '${activeChats.length} conversations',
      '$totalMessages unread messages',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'chat_messages',
          'Chat Messages',
          channelDescription: 'New chat message notifications',
          importance: Importance.high,
          priority: Priority.high,
          groupKey: 'chat_app_group',
          setAsGroupSummary: true,
          icon: '@drawable/ic_stat_notify',
        ),
      ),
    );
  }
}

Future<void> navigateFromNotification(Map<String, dynamic> data) async {
  final chatId = data['chat_id'] as String?;
  final senderId = data['sender_id'] as String?;
  final senderName = data['sender_name'] as String?;

  if (chatId == null || senderId == null || senderName == null) return;

  await removeChatMessages(chatId);

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

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_stat_notify'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: (response) {
      final data = response.payload != null ? jsonDecode(response.payload!) as Map<String, dynamic> : null;
      if (data != null) navigateFromNotification(data);
    },
  );

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler
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
    FirebaseMessaging.onMessage.listen((message) {
      if (message.data.isNotEmpty) {
        final chatId = message.data['chat_id'] as String? ?? '';
        if (ChatPage.activeConvoId != chatId) {
          _showNotification(message.data);
        }
      }
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
