import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RoleContext {
  driver,
  passenger,
}

final roleProvider = StateNotifierProvider<RoleNotifier, RoleContext>((ref) => RoleNotifier());

class RoleNotifier extends StateNotifier<RoleContext> {
  RoleNotifier() : super(RoleContext.passenger);

  void setRole(RoleContext role) {
    state = role;
  }
}
