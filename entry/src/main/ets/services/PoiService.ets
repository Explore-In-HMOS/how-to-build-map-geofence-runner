import { mapCommon, site } from '@kit.MapKit';
import { PoiCategoryDef, PoiType, RunPoi } from '../common/types';

const RUN_POI_SEARCH_RADIUS_M = 3000;
const RUN_POI_PAGE_SIZE = 20;

export class PoiService {
  /** Searches nearby parks/gyms/trails as candidate running destinations, filtered by PoiType. */
  static async searchRunDestinations(center: mapCommon.LatLng): Promise<RunPoi[]> {
    const categories: PoiCategoryDef[] = PoiType.all();
    const resultsByCategory: RunPoi[][] = await Promise.all(
      categories.map((category: PoiCategoryDef) => PoiService.searchByCategory(center, category))
    );
    return resultsByCategory.reduce((all: RunPoi[], part: RunPoi[]) => all.concat(part), []);
  }

  private static async searchByCategory(center: mapCommon.LatLng, category: PoiCategoryDef): Promise<RunPoi[]> {
    const params: site.NearbySearchParams = {
      location: center,
      radius: RUN_POI_SEARCH_RADIUS_M,
      query: category.keyword,
      poiTypes: [category.code],
      pageSize: RUN_POI_PAGE_SIZE,
      sortRule: site.SortRule.DISTANCE
    };
    const result: site.NearbySearchResult = await site.nearbySearch(params);
    const sites: site.Site[] = result.sites ?? [];
    return sites
      .filter((candidate: site.Site) => !!candidate.location)
      .map((candidate: site.Site) => PoiService.toRunPoi(candidate, category));
  }

  private static toRunPoi(candidate: site.Site, category: PoiCategoryDef): RunPoi {
    const runPoi: RunPoi = {
      siteId: candidate.siteId,
      name: candidate.name ?? category.keyword,
      category,
      location: candidate.location as mapCommon.LatLng,
      distanceMeters: candidate.distance,
      formatAddress: candidate.formatAddress
    };
    return runPoi;
  }
}
