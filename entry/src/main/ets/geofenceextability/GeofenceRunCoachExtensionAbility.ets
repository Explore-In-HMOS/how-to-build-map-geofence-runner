import { FenceExtensionAbility, geoLocationManager } from '@kit.LocationKit';
import { GeofenceRegistry } from '../model/GeofenceRegistry';
import { WorkoutSessionState } from '../model/WorkoutSessionState';

/**
 * Geofence ExtensionAbility (module.json5 `extensionAbilities[].type` = "fence"), backed by
 * `FenceExtensionContext`. The system invokes `onFenceStatusChange` directly on registered
 * geofence transitions, independent of the main UI ability's foreground/background state —
 * this is what makes "auto-start workout on entering the gym zone" reliable in the background.
 */
export default class GeofenceRunCoachExtensionAbility extends FenceExtensionAbility {
  onFenceStatusChange(transition: geoLocationManager.GeofenceTransition, additions: Record<string, string>): void {
    const poiName = GeofenceRegistry.lookup(transition.geofenceId) ?? 'a registered running destination';
    const nowMs = new Date().getTime();
    const event = transition.transitionEvent;
    const events = geoLocationManager.GeofenceTransitionEvent;

    if (event === events.GEOFENCE_TRANSITION_EVENT_ENTER) {
      WorkoutSessionState.startTracking(String(transition.geofenceId), poiName, nowMs);
    } else if (event === events.GEOFENCE_TRANSITION_EVENT_EXIT) {
      WorkoutSessionState.completeTracking(nowMs);
    }
  }

  onDestroy(): void {
  }
}
