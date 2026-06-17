part of 'w2g_bloc.dart';

sealed class W2GState {}

final class W2GInitial extends W2GState {}

final class W2GLoading extends W2GState {}

final class W2GRoomLoaded extends W2GState {
  final W2GRoom room;
  final List<W2GChatMessage> messages;
  W2GRoomLoaded({required this.room, this.messages = const []});
}

final class W2GRoomsLoaded extends W2GState {
  final List<W2GRoom> rooms;
  W2GRoomsLoaded(this.rooms);
}

final class W2GRoomCreated extends W2GState {
  final String roomId;
  W2GRoomCreated(this.roomId);
}

final class W2GError extends W2GState {
  final String message;
  W2GError(this.message);
}
