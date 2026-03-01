import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/features/auth/data/datasources/auth_remote_data_sources.dart';
import 'package:chat_application/features/auth/data/repository/auth_repository_impl.dart';
import 'package:chat_application/features/auth/domain/repository/auth_repository.dart';
import 'package:chat_application/features/auth/domain/usecase/current_user.dart';
import 'package:chat_application/features/auth/domain/usecase/user_sign_in.dart';
import 'package:chat_application/features/auth/domain/usecase/user_sign_out.dart';
import 'package:chat_application/features/auth/domain/usecase/user_sign_up.dart';
import 'package:chat_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_application/features/chats/data/datasources/chat_remote_data_sources.dart';
import 'package:chat_application/features/chats/data/models/message_model.dart';
import 'package:chat_application/features/chats/data/repository/chat_repository_impl.dart';
import 'package:chat_application/features/chats/domain/repository/chat_repository.dart';
import 'package:chat_application/features/chats/domain/usecase/get_conversations.dart';
import 'package:chat_application/features/chats/domain/usecase/get_messages.dart';
import 'package:chat_application/features/chats/domain/usecase/search_user.dart';
import 'package:chat_application/features/chats/domain/usecase/send_message.dart';
import 'package:chat_application/features/chats/presentation/bloc/chat/chat_bloc.dart';
import 'package:chat_application/features/chats/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:chat_application/features/chats/presentation/bloc/search/search_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

final serviceLocator = GetIt.instance;

Future<void> initDependencies() async {
  _initAuth();


  //Firebase Instances
  serviceLocator
  ..registerLazySingleton(
    () => FirebaseAuth.instance,
  )
  ..registerLazySingleton(
    () => FirebaseFirestore.instance,
  );

  _initChat();

  //registering core dependencies
  serviceLocator.registerLazySingleton(() => AppUserCubit());

}

void _initAuth() {
  //Data Source
  serviceLocator
  ..registerFactory<AuthRemoteDataSources>(
    () => AuthRemoteDataSourcesImpl(
      firebaseAuth: serviceLocator<FirebaseAuth>(),
      firebaseFirestore: serviceLocator<FirebaseFirestore>(),
    ),
  )

  //Repository
  ..registerFactory<AuthRepository>(
    () => AuthRepositoryImpl(
      serviceLocator<AuthRemoteDataSources>(),
    ),
  )

  //UseCase
  ..registerFactory(
    () => UserSignUp(
      serviceLocator<AuthRepository>(),
    ),
  )
  ..registerFactory(
    () => UserSignIn(
      serviceLocator<AuthRepository>(),
    )
  )
  ..registerFactory(
    () => CurrentUser(
      serviceLocator<AuthRepository>(),
    )
  )
  ..registerFactory(
    () => UserSignOut(
      serviceLocator<AuthRepository>(),
    )
  )

  //Bloc
  ..registerLazySingleton(
    () => AuthBloc(
      userSignUp: serviceLocator<UserSignUp>(), 
      userSignIn: serviceLocator<UserSignIn>(),
      currentUser: serviceLocator<CurrentUser>(),
      userSignOut: serviceLocator<UserSignOut>(),
      appUserCubit: serviceLocator<AppUserCubit>(),
    ),
  );
}

void _initChat()async {
  //Data Source
  serviceLocator
  ..registerFactory<ChatRemoteDataSources>(
    () => ChatRemoteDataSourcesImpl(firestore: serviceLocator<FirebaseFirestore>()),
  )

  ..registerFactory<ChatRepository>(
    () => ChatRepositoryImpl(
      chatRemoteDataSources:  serviceLocator<ChatRemoteDataSources>(),
    ),
  )

  //UseCase
  ..registerFactory(
    () => GetConversations(
      chatRepository:  serviceLocator<ChatRepository>(),
    ),
  )
  ..registerFactory(
    () => GetMessages(
     chatRepository:  serviceLocator<ChatRepository>(),
    )
  )
  ..registerFactory(
    () => SendMessage(
    chatRepository:  serviceLocator<ChatRepository>(),
    )
  )
  ..registerFactory(
    () => SearchUser(
      chatRepository: serviceLocator<ChatRepository>(),
    )
  )

  ..registerLazySingleton(
    () => ChatBloc(
      getMessages: serviceLocator(),
      sendMessage: serviceLocator()
    )
  )

  ..registerLazySingleton(
    ()=> ConversationBloc(
      getConversations: serviceLocator()
    )
  )

  ..registerLazySingleton(
    () => SearchBloc(
      searchUser: serviceLocator<SearchUser>()
    )
  );
}
