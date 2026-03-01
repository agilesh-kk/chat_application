import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_application/features/auth/presentation/pages/auth_gate.dart';
import 'package:chat_application/features/auth/presentation/pages/sign_up_page.dart';
import 'package:chat_application/features/chats/presentation/bloc/chat/chat_bloc.dart';
import 'package:chat_application/features/chats/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:chat_application/features/chats/presentation/bloc/search/search_bloc.dart';
import 'package:chat_application/firebase_options.dart';
import 'package:chat_application/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initDependencies();
  runApp(
    MultiBlocProvider(
      providers: [
        //app user signed in cubit
        BlocProvider(
          create: (_) => serviceLocator<AppUserCubit>(), //loads the app_user_cubit contents from the dependency file
        ),
        BlocProvider(
          create: (_) => serviceLocator<AuthBloc>()
          ..add(AuthCheckRequested()),
        ),
        BlocProvider(
          create: (_) => serviceLocator<ChatBloc>(), 
        ),
        BlocProvider(
          create: (_) => serviceLocator<ConversationBloc>(), 
        ),
        BlocProvider(
          create: (_) => serviceLocator<SearchBloc>(),
        )
      
      ],
      child: MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: AuthGate(),
    );
  }
}
