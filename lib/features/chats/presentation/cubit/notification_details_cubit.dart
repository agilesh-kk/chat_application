import 'package:flutter_bloc/flutter_bloc.dart';

part 'notification_details_state.dart';

class NotificationDetailsCubit extends Cubit<NotificationDetailsState> {
  NotificationDetailsCubit() : super(const NotificationDetailsInitial());

  void setPending({
    required String convoId,
    required String receiverId,
    required String receiverName,
  }) {
    emit(PendingNotificationDetails(
      convoId: convoId,
      receiverId: receiverId,
      receiverName: receiverName,
    ));
  }

  void clearPending() {
    emit(const NoPending());
  }
}
