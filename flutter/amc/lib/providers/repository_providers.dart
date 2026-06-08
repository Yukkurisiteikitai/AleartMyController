import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/remote/google_calendar_api.dart';
import '../data/repository/amc_draft_repository.dart';
import '../data/repository/amc_storage_repository.dart';
import '../data/repository/amc_work_scheduler.dart';
import '../data/repository/auth_repository.dart';
import '../services/amc_work_scheduler_impl.dart';
import '../data/repository/event_repository.dart';
import '../data/repository/observation_event_repository.dart';
import '../data/repository/record_repository.dart';
import 'database_providers.dart';
import 'supabase_providers.dart';

// Supabase が要求する Google OAuth Web Client ID（idToken 取得に必要）。
// defaultValue は local.properties の SUPABASE_GOOGLE_WEB_CLIENT_ID と同値。
const _googleWebClientId = String.fromEnvironment(
  'SUPABASE_GOOGLE_WEB_CLIENT_ID',
  defaultValue:
      '900637494289-fu2ut4f59boqi4a123hpmk6ujequ7a02.apps.googleusercontent.com',
);

final googleSignInProvider = Provider<GoogleSignIn>(
  (ref) => GoogleSignIn(
    scopes: AuthRepository.defaultScopes,
    // web は serverClientId 非対応（index.html の meta タグで代替）。
    serverClientId: kIsWeb ? null : _googleWebClientId,
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(googleSignInProvider),
    ref.watch(supabaseClientProvider),
  ),
);

final googleCalendarApiProvider = Provider<GoogleCalendarApi>(
  (ref) => GoogleCalendarApi(ref.watch(authRepositoryProvider)),
);

final observationEventRepositoryProvider =
    Provider<ObservationEventRepository>(
  (ref) => ObservationEventRepository(ref.watch(observationEventDaoProvider)),
);

final recordRepositoryProvider = Provider<RecordRepository>(
  (ref) => RecordRepository(
    db: ref.watch(appDatabaseProvider),
    recordDao: ref.watch(recordDaoProvider),
    photoDao: ref.watch(photoDaoProvider),
    memoDao: ref.watch(memoDaoProvider),
    observationEventRepository:
        ref.watch(observationEventRepositoryProvider),
    amcDraftDao: ref.watch(amcDraftDaoProvider),
    storageRepository: ref.watch(amcStorageRepositoryProvider),
  ),
);

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepository(
    eventDao: ref.watch(eventDaoProvider),
    observationEventDao: ref.watch(observationEventDaoProvider),
    calendarApi: ref.watch(googleCalendarApiProvider),
  ),
);

final amcWorkSchedulerProvider = Provider<AmcWorkScheduler>(
  (ref) => const WorkmanagerAmcWorkScheduler(),
);

final amcDraftRepositoryProvider = Provider<AmcDraftRepository>(
  (ref) => AmcDraftRepository(
    db: ref.watch(appDatabaseProvider),
    draftDao: ref.watch(amcDraftDaoProvider),
    attachmentDao: ref.watch(amcAttachmentDaoProvider),
    scheduler: ref.watch(amcWorkSchedulerProvider),
  ),
);

final amcStorageRepositoryProvider = Provider<AmcStorageRepository>(
  (ref) => AmcStorageRepository(ref.watch(supabaseClientProvider)),
);
