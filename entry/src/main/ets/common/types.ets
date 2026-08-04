import { mapCommon } from '@kit.MapKit';

/**
 * Running-relevant POI category. `code` maps to MapKit's POI classification system
 * (`NearbySearchParams.poiTypes`) — verify the exact codes against the current MapKit
 * "PoiType" reference appendix before shipping; `keyword` is sent alongside as a
 * text-query fallback so results stay useful even if a code doesn't match.
 */
export interface PoiCategoryDef {
  id: string;
  code: string;
  keyword: string;
  labelKey: string;
}

export class PoiType {
  static readonly PARK: PoiCategoryDef = { id: 'PARK', code: '070101', keyword: 'park', labelKey: 'poi_category_park' };
  static readonly GYM: PoiCategoryDef = { id: 'GYM', code: '070102', keyword: 'gym', labelKey: 'poi_category_gym' };
  static readonly TRAIL: PoiCategoryDef = { id: 'TRAIL', code: '070103', keyword: 'trail', labelKey: 'poi_category_trail' };

  static all(): PoiCategoryDef[] {
    return [PoiType.PARK, PoiType.GYM, PoiType.TRAIL];
  }
}

/** A discovered running destination, trimmed down from a MapKit `site.Site`. */
export interface RunPoi {
  siteId: string;
  name: string;
  category: PoiCategoryDef;
  location: mapCommon.LatLng;
  distanceMeters?: number;
  formatAddress?: string;
}

/** Resolved administrative region for the current position (MapKit Appendixes: city/admin division codes). */
export interface AdminRegion {
  countryCode?: string;
  countryName?: string;
  cityCode?: string;
  cityName?: string;
  adminCode?: string;
}

export interface RouteAvailability {
  supported: boolean;
  reason?: string;
}

/** Aggregated run-history point used to build the running-frequency heat map. */
export interface RunHistoryPoint {
  location: mapCommon.LatLng;
  frequency: number;
}

export enum WorkoutStatus {
  IDLE = 'IDLE',
  TRACKING = 'TRACKING',
  COMPLETED = 'COMPLETED'
}

export interface WorkoutSessionSnapshot {
  status: WorkoutStatus;
  fenceId?: string;
  poiName?: string;
  startTimeMs?: number;
  endTimeMs?: number;
}

export interface RegisteredGeofence {
  geofenceId: number;
  poi: RunPoi;
}
