import 'package:equatable/equatable.dart';

class PasswordState extends Equatable {

  final bool status;

  const PasswordState({
    required this.status
   });
   
  @override
  List<Object?> get props => [
      status
  ];

  factory PasswordState.intial() {
      return const PasswordState(
        status: true
        );
  }

  bool get checked => status == true || false;

  PasswordState copyWith({bool? choix, required bool statut}) {
      return PasswordState( 
        status: statut);
  }

}