import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/common/data/presence_remote_data_source.dart';
import 'package:chat_application/core/data/user_device_data_source.dart';
import 'package:chat_application/core/keys/app_keys.dart';
import 'package:chat_application/features/achievement/data/datasources/achievement_remote_datasource.dart';
import 'package:chat_application/features/achievement/data/repository/achievement_repository_impl.dart';
import 'package:chat_application/features/achievement/domain/repository/achievement_repository.dart';
import 'package:chat_application/features/achievement/domain/usecase/collect_achievement.dart';
import 'package:chat_application/features/achievement/domain/usecase/get_achievements.dart';
import 'package:chat_application/features/achievement/domain/usecase/mark_achievement_seen.dart';
import 'package:chat_application/features/achievement/presentation/bloc/achievement_bloc.dart';
import 'package:chat_application/features/auth/data/datasources/auth_remote_data_sources.dart';
import 'package:chat_application/features/auth/data/repository/auth_repository_impl.dart';
import 'package:chat_application/features/auth/domain/repository/auth_repository.dart';
import 'package:chat_application/features/auth/domain/usecase/current_user.dart';
import 'package:chat_application/features/auth/domain/usecase/user_sign_in.dart';
import 'package:chat_application/features/auth/domain/usecase/user_sign_out.dart';
import 'package:chat_application/features/auth/domain/usecase/user_sign_up.dart';
import 'package:chat_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:chat_application/features/chats/data/datasources/chat_local_data_sources.dart';
import 'package:chat_application/features/chats/data/datasources/chat_remote_data_sources.dart';
import 'package:chat_application/features/chats/data/datasources/typing_remote_data_source.dart';
import 'package:chat_application/features/chats/data/repository/chat_repository_impl.dart';
import 'package:chat_application/features/chats/domain/repository/chat_repository.dart';
import 'package:chat_application/features/chats/domain/usecase/delete_message.dart';
import 'package:chat_application/features/chats/domain/usecase/edit_message.dart';
import 'package:chat_application/features/chats/domain/usecase/get_conversations.dart';
import 'package:chat_application/features/chats/domain/usecase/get_messages.dart';
import 'package:chat_application/features/chats/domain/usecase/get_scheduled_messages.dart';
import 'package:chat_application/features/chats/domain/usecase/mark_messages_delivered.dart';
import 'package:chat_application/features/chats/domain/usecase/search_user.dart';
import 'package:chat_application/features/chats/domain/usecase/send_image.dart';
import 'package:chat_application/features/chats/domain/usecase/send_message.dart';
import 'package:chat_application/features/chats/domain/usecase/toggle_reaction.dart';
import 'package:chat_application/features/chats/presentation/bloc/chat/chat_bloc.dart';
import 'package:chat_application/features/chats/presentation/bloc/time_capsule/time_capsule_bloc.dart';
import 'package:chat_application/features/chats/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:chat_application/features/chats/presentation/bloc/search/search_bloc.dart';
import 'package:chat_application/features/chats/presentation/cubit/convo_typing_cubit.dart';
import 'package:chat_application/features/chats/presentation/cubit/notification_details_cubit.dart';
import 'package:chat_application/features/friends/data/friends_remote_data_sources.dart';
import 'package:chat_application/features/friends/presentation/friends_cubit.dart';
import 'package:chat_application/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:chat_application/features/profile/data/repository/profile_repository_impl.dart';
import 'package:chat_application/features/profile/domain/repository/profile_repository.dart';
import 'package:chat_application/features/profile/domain/usecase/update_bio.dart';
import 'package:chat_application/features/profile/domain/usecase/update_custom_pfp.dart';
import 'package:chat_application/features/profile/domain/usecase/update_profile.dart';
import 'package:chat_application/features/profile/presentation/bloc/bio/bio_bloc.dart';
import 'package:chat_application/features/profile/presentation/bloc/profile_picture/profilePic_bloc.dart';
import 'package:chat_application/features/status/data/datasources/status_local_data_source.dart';
import 'package:chat_application/features/status/data/datasources/status_remote_data_source.dart';
import 'package:chat_application/features/status/data/hiveAdapters/hive_model_adapter.dart';
import 'package:chat_application/features/status/data/model/status_hive_model.dart';
import 'package:chat_application/features/status/data/repository/status_repository_impl.dart';
import 'package:chat_application/features/status/domain/repository/status_repository.dart';
import 'package:chat_application/features/status/domain/usecase/add_like.dart';
import 'package:chat_application/features/status/domain/usecase/delete_status.dart';
import 'package:chat_application/features/status/domain/usecase/get_all_status.dart';
import 'package:chat_application/features/status/domain/usecase/get_views.dart';
import 'package:chat_application/features/status/domain/usecase/update_view.dart';
import 'package:chat_application/features/status/domain/usecase/upload_status.dart';
import 'package:chat_application/features/status/presentation/bloc/status/status_bloc.dart';
import 'package:chat_application/features/status/presentation/bloc/status_view/statusview_bloc.dart';
import 'package:chat_application/features/timeline/data/datasources/timeline_remote_data_sources.dart';
import 'package:chat_application/features/timeline/data/repositories/timeline_repository_impl.dart';
import 'package:chat_application/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:chat_application/features/timeline/domain/usecases/add_personal_event.dart';
import 'package:chat_application/features/timeline/domain/usecases/add_timeline_event.dart';
import 'package:chat_application/features/timeline/domain/usecases/load_events.dart';
import 'package:chat_application/features/timeline/domain/usecases/load_personal_events.dart';
import 'package:chat_application/features/timeline/domain/usecases/remove_personal_event.dart';
import 'package:chat_application/features/timeline/domain/usecases/remove_timeline_event.dart';
import 'package:chat_application/features/timeline/presentation/bloc/personal_time_line/personal_timeline_bloc.dart';
import 'package:chat_application/features/timeline/presentation/bloc/time_line/timeline_bloc.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final serviceLocator = GetIt.instance;

Future<void> initDependencies() async {

  //Firebase Instances
  serviceLocator
  ..registerLazySingleton(
    () => FirebaseAuth.instance,
  )
  ..registerLazySingleton(
    () => FirebaseFirestore.instance,
  )
  ..registerLazySingleton(
    () => FirebaseDatabase.instance,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true
  );

  _initAuth();
  _initChat();
  _initStatus();
  _initProfile();
  _initTimeline();
  _initAchievement();

  //supabase initialization
  final supabase = await Supabase.initialize(
    url: AppKeys.supabaseUrl,
    anonKey: AppKeys.anonKey,
  );

  serviceLocator.registerLazySingleton(() => supabase.client);

  //registering core dependencies
  serviceLocator.registerFactory<PresenceRemoteDataSource>(
    () => PresenceRemoteDataSourceImpl(serviceLocator<FirebaseFirestore>()),
  );
  serviceLocator.registerFactory<UserDeviceDataSource>(
    () => UserDeviceDataSourceImpl(serviceLocator<SupabaseClient>()),
  );
  serviceLocator.registerLazySingleton(() => AppUserCubit(serviceLocator<PresenceRemoteDataSource>(), serviceLocator<UserDeviceDataSource>()));

  serviceLocator.registerFactory<FriendsRemoteDataSource>(()=>FriendsRemoteDataSourceImpl(serviceLocator<FirebaseFirestore>()));

  serviceLocator.registerLazySingleton(() => FriendsCubit(serviceLocator<FriendsRemoteDataSource>()));

  serviceLocator.registerFactory<TypingRemoteDataSource>(
    () => TypingRemoteDataSource(serviceLocator<FirebaseDatabase>()),
  );

  serviceLocator.registerLazySingleton<ConvoTypingCubit>(
    () => ConvoTypingCubit(dataSource: serviceLocator<TypingRemoteDataSource>()),
  );

}

void _initStatus() async{
  Box<StatusHiveModel>? statusBox;

  if (!kIsWeb) {
    await Hive.initFlutter();
    Hive.registerAdapter(StatusHiveModelAdapter());
    final box = await Hive.openBox<StatusHiveModel>("status");
    serviceLocator.registerLazySingleton<Box<StatusHiveModel>>(() => box);
    statusBox = box;
  }

  //data source
  serviceLocator
    ..registerFactory<StatusLocalDataSource>(() => StatusLocalDataSourceImpl(statusBox))
    ..registerFactory<StatusRemoteDataSource>(
      () => StatusRemoteDataSourceImpl(
        supabaseClient: serviceLocator<SupabaseClient>(),
      ),
    )

    //repository
    ..registerFactory<StatusRepository>(
      () => StatusRepositoryImpl(
        statusRemoteDataSource: serviceLocator<StatusRemoteDataSource>(),
        statusLocalDataSource: serviceLocator<StatusLocalDataSource>()
      )
    )

    //usecase
    ..registerFactory(
      () => UploadStatus(
        serviceLocator<StatusRepository>()
      )
    )
    ..registerFactory(
      () => GetAllStatus(
        serviceLocator<StatusRepository>()
      )
    )
    ..registerFactory(
      () => UpdateView(
        serviceLocator<StatusRepository>()
      )
    )
    ..registerFactory(
      () => GetViews(
        serviceLocator<StatusRepository>()
      )
    )
    ..registerFactory(
      () => DeleteStatus(
        serviceLocator<StatusRepository>()
      )
    )
    ..registerFactory(
      () => AddLike(
        statusRepository: serviceLocator<StatusRepository>()
      )
    )

    //bloc
    ..registerLazySingleton(
      () => StatusBloc(
        friends_cubit: serviceLocator<FriendsCubit>(),
        uploadStatus: serviceLocator<UploadStatus>(),
        getAllStatus: serviceLocator<GetAllStatus>(),
        updateView: serviceLocator<UpdateView>(),
        deleteStatus: serviceLocator<DeleteStatus>(),
        addLike: serviceLocator<AddLike>(),
        chatRepository: serviceLocator<ChatRepository>(),
      )
    )
    //status views bloc
    ..registerLazySingleton(
      () => StatusviewBloc(
        getViews: serviceLocator<GetViews>(),
      )
    );
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
      friendsCubit: serviceLocator<FriendsCubit>()
    ),
  );
}

void _initChat()async {
  //Data Source
  serviceLocator
  ..registerLazySingleton<ChatLocalDataSource>(
    () => ChatLocalDataSourceImpl(),
  )

  ..registerFactory<ChatRemoteDataSources>(
    () => ChatRemoteDataSourcesImpl(firestore: serviceLocator<FirebaseFirestore>(),supabase: serviceLocator<SupabaseClient>()),
  )

  ..registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(
      chatRemoteDataSources:  serviceLocator<ChatRemoteDataSources>(),
      chatLocalDataSource: serviceLocator<ChatLocalDataSource>()
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
  ..registerFactory(
    () => SendImage(
      chatRepository: serviceLocator<ChatRepository>(),
    )
  )
  ..registerFactory(
    () => GetScheduledMessages(
      chatRepository: serviceLocator<ChatRepository>(),
    )
  )
  ..registerFactory(
    ()=> DeleteMessage(
      chatRepository: serviceLocator<ChatRepository>()
    )
  )
  ..registerFactory(
    () => MarkMessagesDelivered(chatRepository: serviceLocator<ChatRepository>()),
  )
  ..registerFactory(
    () => ToggleReaction(chatRepository: serviceLocator<ChatRepository>()),
  )
  ..registerFactory(
    () => EditMessage(chatRepository: serviceLocator<ChatRepository>()),
  )

  ..registerLazySingleton(
    () => ChatBloc(
      sendImage: serviceLocator(),
      getMessages: serviceLocator(),
      sendMessage: serviceLocator(),
      deleteMessage: serviceLocator(),
      markMessagesDelivered: serviceLocator(),
      toggleReaction: serviceLocator(),
      editMessage: serviceLocator(),
      chatRepository: serviceLocator<ChatRepository>(),
      chatLocalDataSource: serviceLocator<ChatLocalDataSource>(),
    )
  )

  ..registerFactory(
    () => TimeCapsuleBloc(
      getScheduledMessages: serviceLocator<GetScheduledMessages>()
    )
  )

  ..registerLazySingleton(
    ()=> ConversationBloc(
      friendsCubit: serviceLocator<FriendsCubit>(),
      getConversations: serviceLocator()
    )
  )

  ..registerLazySingleton(
    () => SearchBloc(
      searchUser: serviceLocator<SearchUser>()
    )
  )
  ..registerLazySingleton(
    () => NotificationDetailsCubit(),
  );
}

//for profile feature
void _initProfile() async{
  serviceLocator
  //data source
  ..registerFactory<ProfileRemoteDataSource>(
    () =>ProfileRemoteDataSourceImpl(
      firebaseFirestore: serviceLocator<FirebaseFirestore>(),
      supabaseClient: serviceLocator<SupabaseClient>()
    )
  )

  //repository
  ..registerFactory<ProfileRepository>(
    () => ProfileRepositoryImpl(
      profileRemoteDataSource: serviceLocator<ProfileRemoteDataSource>()
    )
  )

  //usecases
  ..registerFactory(
    () => UpdateProfile(
      profileRepository: serviceLocator<ProfileRepository>(),
    )
  )
  ..registerFactory(
    () => UpdateBio(
      profileRepository: serviceLocator<ProfileRepository>()
    )
  )
  ..registerFactory(
    () => UpdateCustomPfp(
      profileRepository: serviceLocator<ProfileRepository>()
    )
  )

  //bloc for profile pic
  ..registerLazySingleton(
    () => ProfilePicBloc(
      updateProfile: serviceLocator<UpdateProfile>(),
      updateCustomPfp: serviceLocator<UpdateCustomPfp>()
    )
  )

  //bloc for bio
  ..registerLazySingleton(
    () => BioBloc(
      updateBio: serviceLocator<UpdateBio>(),
    ));
  
}

void _initTimeline(){
  serviceLocator
  //data source
  ..registerFactory<TimelineRemoteDataSources>(
    () => TimelineRemoteDataSourcesImpl(firebaseFirestore: serviceLocator<FirebaseFirestore>())
  )

  //repository
  ..registerFactory<TimelineRepository>(
    () => TimelineRepositoryImpl(timelineRemoteDataSources: serviceLocator<TimelineRemoteDataSources>())
  )

  //usecases
  ..registerFactory(
    () => LoadEvents(timelineRepository: serviceLocator<TimelineRepository>())
  )
  ..registerFactory(
    () => AddTimeLineEvent(timelineRepository: serviceLocator<TimelineRepository>()),
  )
  ..registerFactory(
    () => RemoveTimelineEvent(timelineRepository: serviceLocator<TimelineRepository>())
  )
  ..registerFactory(
    () => AddPersonalEvent(timelineRepository: serviceLocator<TimelineRepository>())
  )
  ..registerFactory(
    () => LoadPersonalEvents(timelineRepository: serviceLocator<TimelineRepository>())
  )
  ..registerFactory(
    () => RemovePersonalEvent(timelineRepository: serviceLocator<TimelineRepository>()),
  )
  
  //bloc
  ..registerFactory(
    () => TimelineBloc(
      loadEvents: serviceLocator(),
      addTimeLineEvent: serviceLocator(),
      removeTimelineEvent: serviceLocator(),
    )
  )
  ..registerLazySingleton(
    () => PersonalTimelineBloc(
      addPersonalEvent: serviceLocator(), 
      loadPersonalEvents: serviceLocator(),
      removePersonalEvent: serviceLocator(),
    )
  );
}

void _initAchievement() {
  serviceLocator
  //data source
  ..registerFactory<AchievementRemoteDatasource>(
   () => AchievementRemoteDatasourceImpl(firestore: serviceLocator<FirebaseFirestore>())
  )

  //repository
  ..registerFactory<AchievementRepository>(
    () => AchievementRepositoryImpl(achievementRemoteDatasource: serviceLocator<AchievementRemoteDatasource>())
  )

  //usecase
  ..registerFactory(
    () => CollectAchievement(achievementRepository: serviceLocator<AchievementRepository>())
  )
  ..registerFactory(
    ()=> GetAchievements(achievementRepository: serviceLocator<AchievementRepository>())
  )
  ..registerFactory(
    ()=> MarkAchievementSeen(serviceLocator<AchievementRepository>())
  )

  //bloc
  ..registerLazySingleton(
    () => AchievementBloc(
      getAchievements: serviceLocator<GetAchievements>(), 
      collectAchievement: serviceLocator<CollectAchievement>(), 
      markAchievementSeen: serviceLocator<MarkAchievementSeen>(),
    )
  );
}