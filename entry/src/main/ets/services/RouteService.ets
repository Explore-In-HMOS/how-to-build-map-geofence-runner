import { mapCommon, navi } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { MapReferenceUtil } from '../common/MapReferenceUtil';
import { AdminRegion, RouteAvailability } from '../common/types';

export interface RunRouteResult {
  polyline: mapCommon.LatLng[];
}

export class RouteService {
  /**
   * Gates route requests behind the Countries/Regions Supported for Route Planning
   * appendix check, then requests a walking route (MapKit has no dedicated "running"
   * mode — walking mode is the correct real API for a running route).
   */
  static async planRunRoute(origin: mapCommon.LatLng, destination: mapCommon.LatLng): Promise<RunRouteResult> {
    const region: AdminRegion = await MapReferenceUtil.resolveAdminRegion(origin);
    const availability: RouteAvailability = MapReferenceUtil.checkRoutePlanningSupported(region);
    if (!availability.supported) {
      throw new Error(availability.reason ?? 'Route planning unavailable in this region.');
    }

    const params: navi.RouteParams = {
      origins: [{ latitude: origin.latitude, longitude: origin.longitude }],
      destination: { latitude: destination.latitude, longitude: destination.longitude },
      language: 'en'
    };

    try {
      const result: navi.RouteResult = await navi.getWalkingRoutes(params);
      const firstRoute: navi.Route | undefined = result.routes[0];
      const polyline: mapCommon.LatLng[] = firstRoute?.overviewPolyline ?? [];
      return { polyline };
    } catch (error) {
      if (MapReferenceUtil.isCrossRegionBusinessError(error as BusinessError)) {
        throw new Error('Cross-region route planning is not supported.');
      }
      throw error as Error;
    }
  }
}
