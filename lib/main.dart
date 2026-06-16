import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/keys/app_keys.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_application/features/achievement/presentation/bloc/achievement_bloc.dart';
import 'package:chat_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_application/features/auth/presentation/pages/auth_gate.dart';
import 'package:chat_application/features/chats/presentation/bloc/chat/chat_bloc.dart';
import 'package:chat_application/features/chats/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:chat_application/features/chats/presentation/bloc/search/search_bloc.dart';
import 'package:chat_application/features/chats/presentation/bloc/time_capsule/time_capsule_bloc.dart';
import 'package:chat_application/features/chats/data/datasources/draft_data_source.dart';
import 'package:chat_application/features/chats/presentation/cubit/convo_typing_cubit.dart';
import 'package:chat_application/features/chats/presentation/cubit/in_chat_cubit.dart';
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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_shortcut_plus/flutter_shortcut.dart';
import 'package:fpdart/fpdart.dart' as fp;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;

import 'notification_storage.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
const int _groupSummaryId = 2001;
final Map<String, Person> _personCache = {};

Uint8List createCircularIcon(Uint8List bytes) {
  final src = img.decodeImage(bytes)!;

  const canvasSize = 512;

  final canvas = img.Image(
    width: canvasSize,
    height: canvasSize,
    numChannels: 4,
  );

  img.fill(
    canvas,
    color: img.ColorRgba8(0, 0, 0, 0),
  );

  final resized = img.copyResize(
    src,
    width: src.width > src.height ? canvasSize : null,
    height: src.height >= src.width ? canvasSize : null,
    maintainAspect: true,
  );

  final x = (canvasSize - resized.width) ~/ 2;
  final y = (canvasSize - resized.height) ~/ 2;

  img.compositeImage(
    canvas,
    resized,
    dstX: x,
    dstY: y,
  );

  final result = img.Image(
    width: canvasSize,
    height: canvasSize,
    numChannels: 4,
  );

  final radius = canvasSize / 2;
  final center = radius;

  for (int y = 0; y < canvasSize; y++) {
    for (int x = 0; x < canvasSize; x++) {
      final dx = x - center;
      final dy = y - center;

      if (dx * dx + dy * dy <= radius * radius) {
        result.setPixel(x, y, canvas.getPixel(x, y));
      }
    }
  }

  return Uint8List.fromList(img.encodePng(result));
}

Future<String?> _downloadProfileToLocal(String url) async {
  try {
    final dir = Directory.systemTemp;
    final file = File('${dir.path}${Platform.pathSeparator}shortcut_${url.hashCode}.png');
    if (await file.exists()) return file.path;
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      await file.writeAsBytes(createCircularIcon(response.bodyBytes));
      return file.path;
    }
  } catch (_) {}
  return null;
}

Future<void> createOrUpdateShortcutIfNeeded(
  String senderId,
  String senderName,
  String profile,
) async {
  final prefs = await SharedPreferences.getInstance();

  String? iconPath;
  ShortcutIconAsset iconType;

  if (profile.startsWith('http')) {
    iconPath = await _downloadProfileToLocal(profile);
    iconType = ShortcutIconAsset.fileAsset;
  } else {
    iconPath = profile;
    iconType = ShortcutIconAsset.flutterAsset;
  }

  if (iconPath == null || iconPath.isEmpty) {
    iconPath = 'assets/profile_images/pfp1.png';
    iconType = ShortcutIconAsset.flutterAsset;
  }

  final oldName = prefs.getString('${senderId}_name');
  final oldProfile = prefs.getString('${senderId}_profile');

  if (oldName == senderName && oldProfile == iconPath) {
    return;
  }

  await prefs.setString('${senderId}_name', senderName);
  await prefs.setString('${senderId}_profile', iconPath);

  await FlutterShortcut.pushShortcutItem(
    shortcut: ShortcutItem(
      conversationShortcut: true,
      id: senderId,
      shortLabel: senderName,
      icon: iconPath,
      shortcutIconAsset: iconType,
      action: "shortcut.messages",
    ),
  );
}

@pragma('vm:entry-point')
void notificationActionHandler(final response)async{
  await Firebase.initializeApp();
      if (response.actionId == 'REPLY') {
        final input = response.input;
        final payload = response.payload;
        if (input != null && payload != null) {
          sendReplyFromNotification(input, payload);
        }
      } else {
        final data = response.payload != null ? jsonDecode(response.payload!) as Map<String, dynamic> : null;
        if (data != null) navigateFromNotification(data,true);
      }
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
    onDidReceiveBackgroundNotificationResponse: notificationActionHandler,
    onDidReceiveNotificationResponse: notificationActionHandler
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

Future<void> _showRepliedNotification(String chatId, String text, String currentUserId, String currentUserName, final data) async{
  List<Map<String, dynamic>> messages = await loadChatMessages(chatId);
  messages.add({
    'sender_name': currentUserName,
    'sender_id': currentUserId,
    'text': text,
    'time': DateTime.now().toIso8601String(),
  });

  messages = messages.sortWithDate((e)=>DateTime.parse(e['time']));

  await saveChatMessages(chatId, messages);


  final messagingStyle = MessagingStyleInformation(
    Person(name: data['sender_name'], key: data['sender_id'],important: true,icon: DrawableResourceAndroidIcon("empty")),
    messages: messages.map(
      (m){
        return Message(
          m['text'] ?? '',
          DateTime.parse(m['time'] as String),
          (m['sender_id']==currentUserId)?Person(name: "You",key: "you",icon: DrawableResourceAndroidIcon("empty")):null,
          );
    }).toList(),
    groupConversation: true,
  );

  await flutterLocalNotificationsPlugin.show(
    chatId.hashCode,
    "",
    "",
    NotificationDetails(
      android: AndroidNotificationDetails(
        shortcutId: data["sender_id"],
        'chat_messages',
        'Chat Messages',
        channelDescription: 'New chat message notifications',
        importance: Importance.max,
        priority: Priority.max,
        //color: AppPallete.primaryOrange,
        groupKey: 'chat_app_group',
        icon: '@drawable/ic_stat_notify',
        category: AndroidNotificationCategory.message,
        tag: chatId,
        styleInformation: messagingStyle,
        actions: [
          AndroidNotificationAction(
            'REPLY',
            'Reply',
            inputs: [
              AndroidNotificationActionInput(
                label: 'Reply message...',
                allowFreeFormInput: true,
              ),
            ],
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(
        threadIdentifier: chatId,
      ),
    ),
    payload: jsonEncode(data),
  );
}

Future<void> _showNotification(Map<String, dynamic> data) async {
  final chatId = data['chat_id'] as String? ?? '';
  final senderName = data['sender_name'] as String? ?? '';
  final messageText = data['message'] as String? ?? '';
  final senderId = data['sender_id'] as String? ?? '';
  final profile = data['sender_profile'] as String? ?? '';
  final time = data['created_at'] as String? ?? '';

  createOrUpdateShortcutIfNeeded(senderId, senderName, profile);

  if (chatId.isEmpty) return;

  List<Map<String, dynamic>> messages = await loadChatMessages(chatId);

  if(messages.isNotEmpty && messages.last['sender_id'] != senderId){
    messages.clear();
  }

  messages.add({
    'sender_name': senderName,
    'sender_id': senderId,
    'text': messageText,
    'time': time,
  });

  messages = messages.sortWithDate((e)=>DateTime.parse(e['time']));

  if (messages.length > 10) {
    messages.removeAt(0);
  }
  
  await saveChatMessages(chatId, messages);

  final collapsedTitle = "new message";
  final collapsedBody = "message";

  _personCache[senderId] ??= Person(name: senderName, key: senderId,important: true,icon: DrawableResourceAndroidIcon("empty"));
  for (final m in messages) {
    final sid = m['sender_id'] as String;
    _personCache[sid] ??= Person(name: m['sender_name'] as String, key: sid,important: true,icon: DrawableResourceAndroidIcon("empty"));
  }

  final messagingStyle = MessagingStyleInformation(
    _personCache[senderId]!,
    conversationTitle: senderName,
    messages: messages.map((m) => Message(
      m['text'] ?? '',
      DateTime.parse(m['time'] as String),
      null,
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
        actions: [
          AndroidNotificationAction(
            allowGeneratedReplies: true,
            'REPLY',
            'Reply',
            inputs: [
              AndroidNotificationActionInput(
                label: 'Reply message...',
                allowFreeFormInput: true,
                choices: ["Hello","Okay","What is it?"]
              ),
            ],
          ),
        ],
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
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (context) => ChatPage(convoId: chatId,currentUserId: user.user.id, receiverId: senderId, receiverName: senderName),));
    }
  }
}

Future<void> sendReplyFromNotification(String replyText, String payload) async {
  final data = jsonDecode(payload) as Map<String, dynamic>;
  final chatId = data['chat_id'] as String?;

  if (chatId == null) return;

  final prefs = await SharedPreferences.getInstance();
  final currentUserId = prefs.getString('current_user_id')
      ?? FirebaseAuth.instance.currentUser?.uid;
  final currentUserName = prefs.getString('current_user_name');
  final currentUserProfile = prefs.getString('current_user_profile');

  if (currentUserId == null) {
    await flutterLocalNotificationsPlugin.cancel(chatId.hashCode,tag: chatId);
    await removeChatMessages(chatId);
    return;
  }

  final receiverId = data['sender_id'] as String?;
  if (receiverId == null) {
    await flutterLocalNotificationsPlugin.cancel(chatId.hashCode);
    await removeChatMessages(chatId);
    return;
  }

  final msgId = const Uuid().v4();
  final firestore = FirebaseFirestore.instance;
  final convoRef = firestore.collection("Conversations").doc(chatId);
  _showRepliedNotification(chatId, replyText, currentUserId, currentUserName ?? 'Unknown', data);

  try {

    try {
      final supabase = SupabaseClient(AppKeys.supabaseUrl, AppKeys.anonKey);
      supabase.from('messages').insert({
        'chat_id': chatId,
        'sender_id': currentUserId,
        'receiver_id': receiverId,
        'name': currentUserName ?? 'Unknown',
        'text': replyText,
        'sender_profile': currentUserProfile,
      });
    } catch (_) {}

    final batch = firestore.batch();

    final opRef = convoRef.collection('operation_1').doc();
    final opRef2 = convoRef.collection('operation_2').doc();
        batch.set(opRef, {
          "type": "new_message",
          "messageId": msgId,
          "senderId": currentUserId,
          "content": replyText,
          "messageType": "text",
          "status": "sent",
          "receiverId": receiverId,
          "convoId": chatId,
          "name": currentUserName ?? "Unknown",
          "profile": currentUserProfile ?? "assets/profile_images/pfp1.png",
          "deletedfor": [],
          "deletedForEveryone": false,
          "reactions": {},
          "replyToId": null,
          "replyToContent": null,
          "replyToSenderId": null,
          "replyToType": null,
          "isScheduled": false,
          "inTimeline": false,
          "createdAt": FieldValue.serverTimestamp(),
          "timestamp": FieldValue.serverTimestamp(),
    });

    batch.set(opRef2, {
          "type": "new_message",
          "messageId": msgId,
          "senderId": currentUserId,
          "content": replyText,
          "messageType": "text",
          "status": "sent",
          "receiverId": receiverId,
          "convoId": chatId,
          "name": currentUserName ?? "Unknown",
          "profile": currentUserProfile ?? "assets/profile_images/pfp1.png",
          "deletedfor": [],
          "deletedForEveryone": false,
          "reactions": {},
          "replyToId": null,
          "replyToContent": null,
          "replyToSenderId": null,
          "replyToType": null,
          "isScheduled": false,
          "inTimeline": false,
          "createdAt": FieldValue.serverTimestamp(),
          "timestamp": FieldValue.serverTimestamp(),
    });

    batch.set(convoRef.collection("messages").doc(msgId), {
      'id': msgId,
      'senderId': currentUserId,
      'content': replyText,
      'type': 'text',
      'status': 'sent',
      'createdAt': FieldValue.serverTimestamp(),
      'name': currentUserName ?? 'Unknown',
      'receiverId': receiverId,
      'convoId': chatId,
      'profile': currentUserProfile ?? 'assets/profile_images/pfp1.png',
      'replyToId': null,
      'replyToContent': null,
      'replyToSenderId': null,
      'replyToType': null,
      'deletedfor': [],
      'deletedForEveryone': false,
      'reactions': {},
      'sendAt': null,
      'isScheduled': false,
      'inTimeline': null,
      'index': null,
    });

    batch.set(convoRef, {
      "participantsId": [currentUserId, receiverId],
      "lastupdateTime": FieldValue.serverTimestamp(),
      currentUserId: {
        "receiverId": receiverId,
        "lastMessage": replyText,
        "lastMessageId": msgId,
        "lastSender": currentUserId,
        "lastupdateTime": FieldValue.serverTimestamp(),
      },
      receiverId: {
        "receiverId": currentUserId,
        "unread": FieldValue.increment(1),
        "lastMessage": replyText,
        "lastMessageId": msgId,
        "lastSender": currentUserId,
        "lastupdateTime": FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));

    final userRef = firestore.collection("users").doc(currentUserId);
    final receiverRef = firestore.collection("users").doc(receiverId);
    batch.set(userRef, {
      "friends": FieldValue.arrayUnion([receiverId]),
    }, SetOptions(merge: true));
    batch.set(receiverRef, {
      "friends": FieldValue.arrayUnion([currentUserId]),
    }, SetOptions(merge: true));

    await batch.commit();
  }catch(_){}
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

        BlocProvider(
          create: (_) => serviceLocator<ConvoTypingCubit>(),
        ),

        RepositoryProvider<DraftService>(
          create: (_) => serviceLocator<DraftService>(),
        ),

        BlocProvider(
          create: (_) => serviceLocator<InChatCubit>(),
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
