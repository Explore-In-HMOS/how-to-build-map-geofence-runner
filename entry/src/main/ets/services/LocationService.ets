import { geoLocationManager } from '@kit.LocationKit';
import { mapCommon } from '@kit.MapKit';
import { MapReferenceUtil } from '../common/MapReferenceUtil';

export class LocationService {
  static async getCurrentLatLng(): Promise<mapCommon.LatLng> {
    const request: geoLocationManager.CurrentLocationRequest = {
      priority: geoLocationManager.LocationRequestPriority.ACCURACY,
      timeoutMs: 10000
    };
    const location: geoLocationManager.Location = await geoLocationManager.getCurrentLocation(request);
    return MapReferenceUtil.toLatLng(location.latitude, location.longitude);
  }
}
