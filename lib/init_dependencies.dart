import 'package:chat_application/features/auth/data/datasources/auth_remote_data_sources.dart';
import 'package:chat_application/features/auth/data/repository/auth_repository_impl.dart';
import 'package:chat_application/features/auth/domain/repository/auth_repository.dart';
import 'package:chat_application/features/auth/domain/usecase/current_user.dart';
import 'package:chat_application/features/auth/domain/usecase/user_sign_in.dart';
import 'package:chat_application/features/auth/domain/usecase/user_sign_up.dart';
import 'package:chat_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

final serviceLocator = GetIt.instance;

Future<void> initDependencies() async {
  _initAuth();

  //Firebase Instances
  serviceLocator.registerLazySingleton(
    () => FirebaseAuth.instance,
  );

  serviceLocator.registerLazySingleton(
    () => FirebaseFirestore.instance,
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

  //Bloc
  ..registerLazySingleton(
    () => AuthBloc(
      userSignUp: serviceLocator<UserSignUp>(), 
      userSignIn: serviceLocator<UserSignIn>(),
      currentUser: serviceLocator<CurrentUser>(),
    ),
  );
}
