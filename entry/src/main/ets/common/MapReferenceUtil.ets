import { mapCommon, site } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AdminRegion, RouteAvailability } from './types';

/**
 * MapKit Appendixes reference table: Countries/Regions Supported for Route Planning.
 * ISO 3166-1 alpha-2 codes, matching `AddressComponent.countryCode`.
 * This is a representative subset for the codelab — verify/replace against the
 * current MapKit "Countries/Regions Supported for Route Planning" appendix before shipping.
 */
const ROUTE_PLANNING_SUPPORTED_COUNTRY_CODES: Set<string> = new Set<string>([
  'CN', 'HK', 'MO', 'TW',
  'DE', 'FR', 'GB', 'IT', 'ES', 'NL', 'BE', 'IE', 'PT', 'PL', 'AT', 'CH',
  'US', 'CA', 'MX', 'BR',
  'SG', 'MY', 'TH', 'AE', 'SA',
  'AU', 'NZ'
]);

/** Cross-region route planning error surfaced by `navi.getWalkingRoutes`/`getDrivingRoutes`/etc. */
const BUSINESS_ERROR_CROSS_REGION_NOT_SUPPORTED = 1002602002;

export class MapReferenceUtil {
  /**
   * Resolves the administrative region (country/city/admin-division codes) for a position
   * via MapKit reverse geocoding, so region-scoped filtering/regulations don't require an
   * extra network round trip beyond the one reverse-geocode call.
   */
  static async resolveAdminRegion(location: mapCommon.LatLng): Promise<AdminRegion> {
    const result: site.ReverseGeocodeResult = await site.reverseGeocode({ location });
    const component: site.AddressComponent = result.addressComponent;
    const region: AdminRegion = {
      countryCode: component.countryCode,
      countryName: component.countryName,
      cityCode: component.city?.cityCode,
      cityName: component.city?.cityName,
      adminCode: component.adminCode
    };
    return region;
  }

  /**
   * Client-side pre-check against the Countries/Regions Supported for Route Planning
   * appendix, run before every route request so travel to an unsupported region fails
   * fast with a clear message instead of a raw route-request error.
   */
  static checkRoutePlanningSupported(region: AdminRegion): RouteAvailability {
    if (!region.countryCode) {
      return { supported: false, reason: 'Unable to determine current country/region.' };
    }
    if (!ROUTE_PLANNING_SUPPORTED_COUNTRY_CODES.has(region.countryCode)) {
      return { supported: false, reason: `Route planning is not supported in region "${region.countryCode}".` };
    }
    return { supported: true };
  }

  /** True when a route-request failure is MapKit's own cross-region-not-supported error. */
  static isCrossRegionBusinessError(error: BusinessError): boolean {
    return error.code === BUSINESS_ERROR_CROSS_REGION_NOT_SUPPORTED;
  }

  /**
   * Coordinate-system normalization per the MapKit Appendixes: `mapCommon.LatLng` and the
   * MapKit route/site APIs consume WGS-84 coordinates directly. Raw device GPS fixes
   * (`geoLocationManager.Location`, already WGS-84) are passed through this single helper
   * rather than handed to overlays ad hoc, so any future coordinate-system caveat only
   * needs to be applied in one place.
   */
  static toLatLng(latitude: number, longitude: number): mapCommon.LatLng {
    return { latitude, longitude };
  }
}
