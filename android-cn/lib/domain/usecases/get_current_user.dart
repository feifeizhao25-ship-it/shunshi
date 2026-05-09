// lib/domain/usecases/get_current_user.dart
import '../entities/user.dart';
import '../repositories/user_repository.dart';

class GetCurrentUserUseCase {
  final UserRepository _repository;
  GetCurrentUserUseCase(this._repository);

  Future<User?> call() => _repository.getCurrentUser();
}
