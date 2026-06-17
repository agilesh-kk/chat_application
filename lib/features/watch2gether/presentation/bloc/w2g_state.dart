part of 'w2g_bloc.dart';

sealed class W2GState {}

final class W2GInitial extends W2GState {}

final class W2GLoading extends W2GState {}

final class W2GRoomLoaded extends W2GState {
  final W2GRoom room;
  final List<W2GChatMessage> messages;
  final Set<String> typingUserIds;
  W2GRoomLoaded({required this.room, this.messages = const [], this.typingUserIds = const {}});
}

final class W2GHomeLoaded extends W2GState {
  final W2GRoom? activeRoom;
  W2GHomeLoaded({this.activeRoom});
}

final class W2GRoomCreated extends W2GState {
  final String roomId;
  final String roomName;
  final String createdBy;
  W2GRoomCreated({required this.roomId, required this.roomName, required this.createdBy});
}

final class W2GError extends W2GState {
  final String message;
  W2GError(this.message);
}
