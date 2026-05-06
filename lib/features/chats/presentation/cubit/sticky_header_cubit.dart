import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'sticky_header_state.dart';

class StickyHeaderCubit extends Cubit<StickyHeaderState> {
  Timer? _hideTimer;

  StickyHeaderCubit() : super(const StickyHeaderInitial());

  void updateDateLabel(String? label) {
    emit(StickyHeaderUpdate(dateLabel: label, showHeader: true));
    _resetHideTimer();
  }

  void hide() {
    emit(StickyHeaderUpdate(
      dateLabel: state.dateLabel,
      showHeader: false,
    ));
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 1), () {
      hide();
    });
  }

  @override
  Future<void> close() {
    _hideTimer?.cancel();
    return super.close();
  }
}
