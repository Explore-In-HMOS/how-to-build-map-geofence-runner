import { geoLocationManager } from '@kit.LocationKit';
import { RegisteredGeofence, RunPoi } from '../common/types';

const DEFAULT_POI_FENCE_RADIUS_M = 100;
const DEFAULT_FENCE_EXPIRATION_MS = 24 * 60 * 60 * 1000;

export class GeofenceService {
  /**
   * Registers a geofence around a selected POI. Background enter/exit delivery is handled
   * by `GeofenceRunCoachExtensionAbility` (FenceExtensionContext); `geofenceTransitionCallback`
   * here is a foreground safety net for while this ability instance is still alive.
   */
  static async registerPoiGeofence(
    poi: RunPoi,
    onForegroundTransition: (transition: geoLocationManager.GeofenceTransition) => void
  ): Promise<RegisteredGeofence> {
    const request: geoLocationManager.GnssGeofenceRequest = {
      geofence: {
        latitude: poi.location.latitude,
        longitude: poi.location.longitude,
        coordinateSystemType: geoLocationManager.CoordinateSystemType.WGS84,
        radius: DEFAULT_POI_FENCE_RADIUS_M,
        expiration: DEFAULT_FENCE_EXPIRATION_MS
      },
      monitorTransitionEvents: [
        geoLocationManager.GeofenceTransitionEvent.GEOFENCE_TRANSITION_EVENT_ENTER,
        geoLocationManager.GeofenceTransitionEvent.GEOFENCE_TRANSITION_EVENT_EXIT
      ],
      geofenceTransitionCallback: (error, transition: geoLocationManager.GeofenceTransition) => {
        if (!error) {
          onForegroundTransition(transition);
        }
      }
    };
    const geofenceId: number = await geoLocationManager.addGnssGeofence(request);
    return { geofenceId, poi };
  }

  static async unregisterGeofence(geofenceId: number): Promise<void> {
    await geoLocationManager.removeGnssGeofence(geofenceId);
  }
}
