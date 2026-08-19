import '../../data/models/ai_response.dart';
import '../../data/models/user_context.dart';
import '../repositories/ai_repository.dart';

class GenerateDailyPlan {
  final AiRepository _repository;

  GenerateDailyPlan(this._repository);

  Future<AiResponse> call({
    required String userId,
    required UserContext context,
  }) async {
    return _repository.generateDailyPlan(
      userId: userId,
      context: context,
    );
  }
}
