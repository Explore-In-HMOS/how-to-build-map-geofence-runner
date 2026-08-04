import { WorkoutSessionSnapshot, WorkoutStatus } from '../common/types';

/**
 * Storage keys backing a workout session in `AppStorage`. `AppStorage` (core ArkUI state,
 * not an extra Kit) is used instead of a plain in-memory singleton because a geofence
 * "enter"/"exit" transition can be delivered to `GeofenceRunCoachExtensionAbility`
 * (see geofenceextability/GeofenceRunCoachExtensionAbility.ets) independently of whatever
 * ability instance owns the map UI — both need to converge on one session record.
 */
export const WORKOUT_STATUS_KEY = 'workoutStatus';
export const WORKOUT_FENCE_ID_KEY = 'workoutFenceId';
export const WORKOUT_POI_NAME_KEY = 'workoutPoiName';
export const WORKOUT_START_TIME_KEY = 'workoutStartTimeMs';
export const WORKOUT_END_TIME_KEY = 'workoutEndTimeMs';

export class WorkoutSessionState {
  static startTracking(fenceId: string, poiName: string, nowMs: number): void {
    AppStorage.setOrCreate<string>(WORKOUT_STATUS_KEY, WorkoutStatus.TRACKING);
    AppStorage.setOrCreate<string>(WORKOUT_FENCE_ID_KEY, fenceId);
    AppStorage.setOrCreate<string>(WORKOUT_POI_NAME_KEY, poiName);
    AppStorage.setOrCreate<number>(WORKOUT_START_TIME_KEY, nowMs);
  }

  static completeTracking(nowMs: number): void {
    AppStorage.setOrCreate<string>(WORKOUT_STATUS_KEY, WorkoutStatus.COMPLETED);
    AppStorage.setOrCreate<number>(WORKOUT_END_TIME_KEY, nowMs);
  }

  static reset(): void {
    AppStorage.setOrCreate<string>(WORKOUT_STATUS_KEY, WorkoutStatus.IDLE);
    AppStorage.delete(WORKOUT_FENCE_ID_KEY);
    AppStorage.delete(WORKOUT_POI_NAME_KEY);
    AppStorage.delete(WORKOUT_START_TIME_KEY);
    AppStorage.delete(WORKOUT_END_TIME_KEY);
  }

  static snapshot(): WorkoutSessionSnapshot {
    const status = AppStorage.get<string>(WORKOUT_STATUS_KEY) as WorkoutStatus | undefined;
    return {
      status: status ?? WorkoutStatus.IDLE,
      fenceId: AppStorage.get<string>(WORKOUT_FENCE_ID_KEY),
      poiName: AppStorage.get<string>(WORKOUT_POI_NAME_KEY),
      startTimeMs: AppStorage.get<number>(WORKOUT_START_TIME_KEY),
      endTimeMs: AppStorage.get<number>(WORKOUT_END_TIME_KEY)
    };
  }
}
