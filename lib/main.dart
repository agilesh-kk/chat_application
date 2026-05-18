import 'dart:async';
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
import 'package:chat_application/features/chats/presentation/cubit/notification_details_cubit.dart';
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
import 'package:flutter_shortcut_plus/flutter_shortcut.dart';
import 'package:fpdart/fpdart.dart' as fp;
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_storage.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
const int _groupSummaryId = 2001;
final Map<String, Person> _personCache = {};

Future<void> createConversationShortcut(String senderId, String senderName, String profile) async {
  await FlutterShortcut.pushShortcutItem(
    shortcut: ShortcutItem(
      conversationShortcut: true,
      id: senderId, 
      shortLabel: senderName,
      icon: profile,
      action: "shortcut.messages",
      shortcutIconAsset: ShortcutIconAsset.flutterAsset
    ),
  );
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await _initNotification();
  await _showNotification(message.data);
}

Future<void> _initNotification() async {
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_stat_notify'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: (response) {
      final data = response.payload != null ? jsonDecode(response.payload!) as Map<String, dynamic> : null;
      if (data != null) navigateFromNotification(data,true);
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
    'chat_messages1',
    'Chat Messages v1',
    description: 'New chat message notifications',
    importance: Importance.max,
    enableVibration: true,
    playSound: true,
    groupId: 'chat_app_group',
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<void> _showNotification(Map<String, dynamic> data) async {
  final chatId = data['chat_id'] as String? ?? '';
  final senderName = data['sender_name'] as String? ?? '';
  final messageText = data['message'] as String? ?? '';
  final senderId = data['sender_id'] as String? ?? '';
  final profile = data['sender_profile'] as String? ?? '';

  createConversationShortcut(senderId, senderName, profile);

  if (chatId.isEmpty) return;

  final List<Map<String, dynamic>> messages = await loadChatMessages(chatId);
  messages.add({
    'sender_name': senderName,
    'sender_id': senderId,
    'text': messageText,
    'time': DateTime.now().toIso8601String(),
  });

  messages.sortWithDate((e)=>DateTime.parse(e['time']));

  if (messages.length > 5) {
    messages.removeAt(0);
  }
  await saveChatMessages(chatId, messages);

  final collapsedTitle = "new message";
  final collapsedBody = "message";

  _personCache[senderId] ??= Person(name: senderName, key: senderId,important: true);
  for (final m in messages) {
    final sid = m['sender_id'] as String;
    _personCache[sid] ??= Person(name: m['sender_name'] as String, key: sid,important: true);
  }

  final messagingStyle = MessagingStyleInformation(
    _personCache[senderId]!,
    conversationTitle: senderName,
    messages: messages.map((m) => Message(
      m['text'] ?? '',
      DateTime.parse(m['time'] as String),
      _personCache[m['sender_id'] as String]!,
    )).toList(),
    groupConversation: false,
  );

  await flutterLocalNotificationsPlugin.show(
    chatId.hashCode,
    collapsedTitle,
    collapsedBody,
    NotificationDetails(
      android: AndroidNotificationDetails(
        shortcutId: senderId,
        'chat_messages1',
        'Chat Messages v1',
        channelDescription: 'New chat message notifications',
        importance: Importance.max,
        priority: Priority.max,
        //color: AppPallete.primaryOrange,
        groupKey: 'chat_app_group',
        icon: '@drawable/ic_stat_notify',
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
          'chat_messages1',
          'Chat Messages v1',
          channelDescription: 'New chat message notifications',
          importance: Importance.max,
          priority: Priority.max,
          groupKey: 'chat_app_group',
          setAsGroupSummary: true,
          icon: '@drawable/ic_stat_notify',
        ),
      ),
    );
  }
}

Future<void> navigateFromNotification(Map<String, dynamic> data, bool terminated) async {
  final chatId = data['chat_id'] as String?;
  final senderId = data['sender_id'] as String?;
  final senderName = data['sender_name'] as String?;

  if (chatId == null || senderId == null || senderName == null) return;

  await removeChatMessages(chatId);

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('sender_id', senderId);
  await prefs.setString('sender_name', senderName);

  if(navigatorKey.currentState != null){
    final user = serviceLocator<AppUserCubit>().state;
    if(user is AppUserIsSignedin) {
      await prefs.remove("sender_id");
      await prefs.remove("sender_name");
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (context) => ChatPage(currentUserId: user.user.id, receiverId: senderId, receiverName: senderName),));
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseMessaging.instance.requestPermission();

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler
  );

  await _initNotification();

  final launchDetails = await flutterLocalNotificationsPlugin
      .getNotificationAppLaunchDetails();
  if (launchDetails?.didNotificationLaunchApp == true) {
    final payload = launchDetails?.notificationResponse?.payload;
    if (payload != null) {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final chatId = data['chat_id'] as String?;
      final senderId = data['sender_id'] as String?;
      final senderName = data['sender_name'] as String?;
      if (chatId != null && senderId != null && senderName != null) {
        await removeChatMessages(chatId);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sender_id', senderId);
        await prefs.setString('sender_name', senderName);
      }
    }
  }

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

        BlocProvider(
          create: (context) => serviceLocator<NotificationDetailsCubit>(),
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
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      navigateFromNotification(msg.data,false);
    });
    FirebaseMessaging.onMessage.listen((message) {
      //print("sdfffffffffffffffffffffffffffff");
      if (message.data.isNotEmpty) {
        final chatId = message.data['chat_id'] as String? ?? '';
        if (ChatPage.activeConvoId != chatId) {
          try{
            _showNotification(message.data);
          }catch(e){
            //print(e);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
