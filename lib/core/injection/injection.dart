import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:taskbite/core/audio/audio_recorder_service.dart';
import 'package:taskbite/core/localization/cubit/localization_cubit.dart';
import 'package:taskbite/features/ai/data/ai_config.dart';
import 'package:taskbite/features/ai/data/ai_task_draft_parser.dart';
import 'package:taskbite/features/ai/data/http_ai_task_repository.dart';
import 'package:taskbite/features/ai/data/http_transcription_repository.dart';
import 'package:taskbite/features/ai/domain/repositories/ai_task_repository.dart';
import 'package:taskbite/features/ai/domain/repositories/audio_transcription_repository.dart';
import 'package:taskbite/features/settings/cubits/settings_cubit.dart';
import 'package:taskbite/features/tasks/data/repositories/hive_task_repository.dart';
import 'package:taskbite/features/tasks/domain/repositories/task_repository.dart';
import 'package:taskbite/features/tasks/presentation/cubit/tasks_cubit.dart';

GetIt getIt = GetIt.instance;

initGetIt() {
  // Cubits without dependencies
  getIt.registerFactory<LocalizationCubit>(() => LocalizationCubit());
  getIt.registerFactory<SettingsCubit>(() => SettingsCubit());

  // Data / domain layer
  getIt.registerLazySingleton<TaskRepository>(() => HiveTaskRepository());

  // AI pipeline configuration is read once from the build environment. No
  // secret is required in the app when both endpoints point at a proxy.
  final aiConfig = AiConfig.fromEnvironment();
  getIt.registerLazySingleton<AudioTranscriptionRepository>(
    () => HttpTranscriptionRepository(config: aiConfig, client: http.Client()),
  );
  getIt.registerLazySingleton<AiTaskRepository>(
    () => HttpAiTaskRepository(
      config: aiConfig,
      parser: const AiTaskDraftParser(),
      client: http.Client(),
    ),
  );
  // A fresh audio recorder per composer session
  getIt.registerFactory<AudioRecorderService>(() => AudioRecorderService());

  // Cubits that depend on repositories
  getIt.registerFactory<TasksCubit>(() => TasksCubit(getIt<TaskRepository>()));
}
