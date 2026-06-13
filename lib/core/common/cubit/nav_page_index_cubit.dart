import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'nav_page_state.dart';

@immutable
class NavPageIndexCubit extends Cubit<NavPageState>{
  NavPageIndexCubit() : super(NavPageInitial());

  void pageChanged(int index){
    emit(NavPageChanged(index: index));
  }

  void navigateToChat(String receiverId, String receiverName) {
    emit(NavPageChanged(index: 0, chatReceiverId: receiverId, chatReceiverName: receiverName));
  }
  
}