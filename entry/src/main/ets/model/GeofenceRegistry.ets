/**
 * Maps a registered geofence ID back to its POI name, shared via `AppStorage` (same-process
 * default for this HAP's abilities) so `GeofenceRunCoachExtensionAbility` can label a
 * transition it receives without re-querying MapKit from the extension-ability context.
 */
const GEOFENCE_REGISTRY_KEY = 'geofencePoiNameById';

export class GeofenceRegistry {
  private static readAll(): Record<string, string> {
    const raw = AppStorage.get<string>(GEOFENCE_REGISTRY_KEY);
    if (!raw) {
      return {};
    }
    return JSON.parse(raw) as Record<string, string>;
  }

  static register(geofenceId: number, poiName: string): void {
    const all = GeofenceRegistry.readAll();
    all[String(geofenceId)] = poiName;
    AppStorage.setOrCreate<string>(GEOFENCE_REGISTRY_KEY, JSON.stringify(all));
  }

  static unregister(geofenceId: number): void {
    const all = GeofenceRegistry.readAll();
    const removedKey = String(geofenceId);
    const remaining: Record<string, string> = {};
    Object.keys(all).forEach((key: string) => {
      if (key !== removedKey) {
        remaining[key] = all[key];
      }
    });
    AppStorage.setOrCreate<string>(GEOFENCE_REGISTRY_KEY, JSON.stringify(remaining));
  }

  static lookup(geofenceId: number): string | undefined {
    return GeofenceRegistry.readAll()[String(geofenceId)];
  }
}
