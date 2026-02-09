import 'package:hooks_riverpod/legacy.dart';
import 'package:wouritv/presentation/component/view_models/password_state.dart';

final passwordViewModelProvider = StateNotifierProvider.autoDispose<PasswordViewModel, PasswordState>(
  (ref) => PasswordViewModel());

class PasswordViewModel extends StateNotifier<PasswordState> {

    PasswordViewModel() : super(PasswordState.intial());

    void submitAnswer(bool answer) {

       if(answer == true) {
         state = state.copyWith(
            statut: true
          );
       }

       else {
         state = state.copyWith(
            statut: false
          );
       }
 
    }

    void reset() {
      state = PasswordState.intial();
    }


}