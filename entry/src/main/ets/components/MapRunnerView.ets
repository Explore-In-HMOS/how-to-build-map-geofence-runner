import { map, mapCommon, MapComponent } from '@kit.MapKit';
import { geoLocationManager } from '@kit.LocationKit';
import { common } from '@kit.AbilityKit';
import { ArcList, ArcListAttribute, ArcListItem, ArcListItemAttribute, LengthMetrics } from '@kit.ArkUI';
import { LocationService } from '../services/LocationService';
import { PoiService } from '../services/PoiService';
import { RouteService, RunRouteResult } from '../services/RouteService';
import { HeatmapService } from '../services/HeatmapService';
import { GeofenceService } from '../services/GeofenceService';
import { PermissionService } from '../services/PermissionService';
import { MapReferenceUtil } from '../common/MapReferenceUtil';
import { WorkoutSessionState, WORKOUT_POI_NAME_KEY, WORKOUT_STATUS_KEY } from '../model/WorkoutSessionState';
import { GeofenceRegistry } from '../model/GeofenceRegistry';
import { AdminRegion, RegisteredGeofence, RouteAvailability, RunPoi, WorkoutStatus } from '../common/types';
import { PoiListPanel } from './PoiListPanel';

const DEFAULT_CENTER: mapCommon.LatLng = { latitude: 41.0082, longitude: 28.9784 };
const DEFAULT_ZOOM = 14;
const ROUTE_LINE_COLOR = 0xFF0A84FF;

@Component
export struct MapRunnerView {
  @State private currentLocation: mapCommon.LatLng = DEFAULT_CENTER;
  @State private pois: RunPoi[] = [];
  @State private selectedPoi: RunPoi | undefined = undefined;
  @State private region: AdminRegion | undefined = undefined;
  @State private routeAvailability: RouteAvailability | undefined = undefined;
  @State private heatmapVisible: boolean = false;
  @State private statusMessage: string = 'Grant location access, then tap "Find Runs".';
  @State private registeredGeofence: RegisteredGeofence | undefined = undefined;
  @State private currentPageIndex: number = 0;

  @StorageProp(WORKOUT_STATUS_KEY) workoutStatus: string = WorkoutStatus.IDLE;
  @StorageProp(WORKOUT_POI_NAME_KEY) workoutPoiName: string = '';

  private mapController: map.MapComponentController | undefined = undefined;
  private markerOverlays: map.Marker[] = [];
  private routeOverlay: map.MapPolyline | undefined = undefined;
  private massPointOverlay: map.MassPointOverlay | undefined = undefined;
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;

  build() {
    // Two full-bleed swipeable pages instead of a vertical split: a round display clips
    // both X and Y from the center, so stacking "map on top / list on bottom" pushes list
    // content toward the poles where it gets cut into a sliver. Full-screen-per-page (map,
    // then an ArcList that's pole-aware by design) avoids that entirely.
    Swiper() {
      Stack({ alignContent: Alignment.Bottom }) {
        MapComponent({
          mapOptions: {
            position: { target: this.currentLocation, zoom: DEFAULT_ZOOM }
          },
          mapCallback: (err, controller: map.MapComponentController) => {
            if (!err) {
              this.mapController = controller;
              this.mapController.setMyLocationEnabled(true);
              this.onMapReady();
            }
          }
        })
          .width('100%')
          .height('100%')

        Row({ space: 6 }) {
          Button('Find Runs')
            .fontSize(10)
            .onClick(() => {
              this.discoverPois();
            })
          Button(this.heatmapVisible ? 'Hide Heat' : 'Show Heat')
            .fontSize(10)
            .onClick(() => {
              this.toggleHeatmap();
            })
        }
        .justifyContent(FlexAlign.Center)
        .width('90%')
        .margin({ bottom: 24 })
      }
      .width('100%')
      .height('100%')

      ArcList({ initialIndex: 0 }) {
        ArcListItem() {
          Text(this.statusMessage)
            .fontSize(11)
            .textAlign(TextAlign.Center)
            .maxLines(3)
        }
        .align(Alignment.Center)

        ArcListItem() {
          Text(`Region: ${this.region?.cityName ?? this.region?.countryName ?? '-'}`)
            .fontSize(10)
            .fontColor(Color.Gray)
            .textAlign(TextAlign.Center)
        }
        .align(Alignment.Center)

        ArcListItem() {
          Text(`Workout: ${this.workoutStatus}${this.workoutPoiName ? ` @ ${this.workoutPoiName}` : ''}`)
            .fontSize(10)
            .fontColor(Color.Gray)
            .textAlign(TextAlign.Center)
        }
        .align(Alignment.Center)

        if (this.pois.length > 0) {
          PoiListPanel({
            pois: this.pois,
            selectedSiteId: this.selectedPoi?.siteId ?? '',
            onSelect: (poi: RunPoi) => {
              this.selectPoi(poi);
            }
          })
        }

        if (this.selectedPoi && this.routeAvailability && !this.routeAvailability.supported) {
          ArcListItem() {
            Text(this.routeAvailability.reason ?? 'Route planning unavailable here.')
              .fontSize(10)
              .fontColor(Color.Red)
              .textAlign(TextAlign.Center)
          }
          .align(Alignment.Center)
        }

        if (this.selectedPoi && this.routeAvailability?.supported) {
          ArcListItem() {
            Button(this.registeredGeofence ? 'Geofence Registered' : 'Register Geofence')
              .fontSize(10)
              .enabled(!this.registeredGeofence)
              .onClick(() => {
                this.registerGeofenceForSelectedPoi();
              })
          }
          .align(Alignment.Center)
        }
      }
      .space(LengthMetrics.px(16))
      .width('100%')
      .height('100%')
    }
    .index(this.currentPageIndex)
    .width('100%')
    .height('100%')
  }

  private async onMapReady(): Promise<void> {
    const granted = await PermissionService.ensureLocationPermissions(this.context);
    if (!granted) {
      this.statusMessage = 'Location permission denied — showing default area.';
      return;
    }
    try {
      this.currentLocation = await LocationService.getCurrentLatLng();
      const controller = this.mapController;
      if (controller) {
        controller.animateCamera(
          map.newCameraPosition({ target: this.currentLocation, zoom: DEFAULT_ZOOM }),
          300
        );
      }
      this.region = await MapReferenceUtil.resolveAdminRegion(this.currentLocation);
      this.statusMessage = 'Tap "Find Runs" to discover nearby destinations.';
    } catch (error) {
      this.statusMessage = 'Using default location (live location unavailable).';
    }
  }

  private async discoverPois(): Promise<void> {
    this.statusMessage = 'Searching nearby parks, gyms, and trails...';
    try {
      this.pois = await PoiService.searchRunDestinations(this.currentLocation);
      this.statusMessage = this.pois.length > 0
        ? `${this.pois.length} destinations found.`
        : 'No running destinations found nearby.';
      this.renderPoiMarkers();
      if (this.pois.length > 0) {
        this.currentPageIndex = 1;
      }
    } catch (error) {
      this.statusMessage = 'POI search failed.';
    }
  }

  private renderPoiMarkers(): void {
    const controller = this.mapController;
    if (!controller) {
      return;
    }
    this.markerOverlays.forEach((marker: map.Marker) => {
      marker.remove();
    });
    this.markerOverlays = [];
    this.pois.forEach((poi: RunPoi) => {
      controller.addMarker({ position: poi.location }).then((marker: map.Marker) => {
        this.markerOverlays.push(marker);
      });
    });
  }

  private async selectPoi(poi: RunPoi): Promise<void> {
    this.selectedPoi = poi;
    this.registeredGeofence = undefined;
    this.statusMessage = `Planning route to ${poi.name}...`;
    try {
      const region = await MapReferenceUtil.resolveAdminRegion(this.currentLocation);
      this.region = region;
      this.routeAvailability = MapReferenceUtil.checkRoutePlanningSupported(region);
      if (!this.routeAvailability.supported) {
        this.statusMessage = this.routeAvailability.reason ?? 'Route planning unavailable here.';
        return;
      }
      const route: RunRouteResult = await RouteService.planRunRoute(this.currentLocation, poi.location);
      this.renderRoute(route);
      this.statusMessage = `Route ready to ${poi.name}.`;
    } catch (error) {
      this.statusMessage = (error as Error).message;
    }
  }

  private renderRoute(route: RunRouteResult): void {
    const controller = this.mapController;
    if (!controller || route.polyline.length === 0) {
      return;
    }
    this.routeOverlay?.remove();
    controller
      .addPolyline({ points: route.polyline, width: 8, color: ROUTE_LINE_COLOR })
      .then((polyline: map.MapPolyline) => {
        this.routeOverlay = polyline;
      });
  }

  private async toggleHeatmap(): Promise<void> {
    const controller = this.mapController;
    if (!controller) {
      return;
    }
    if (this.heatmapVisible) {
      this.massPointOverlay?.setVisible(false);
      this.heatmapVisible = false;
      return;
    }
    if (this.massPointOverlay) {
      this.massPointOverlay.setVisible(true);
      this.heatmapVisible = true;
      return;
    }
    const history = HeatmapService.getMockRunHistory(this.currentLocation);
    this.massPointOverlay = await HeatmapService.renderHeatmap(controller, history, $r('app.media.location_indicator_red'));
    this.heatmapVisible = true;
  }

  private async registerGeofenceForSelectedPoi(): Promise<void> {
    const poi = this.selectedPoi;
    if (!poi) {
      return;
    }
    const registered: RegisteredGeofence = await GeofenceService.registerPoiGeofence(
      poi,
      (transition: geoLocationManager.GeofenceTransition) => {
        const nowMs = new Date().getTime();
        const event = transition.transitionEvent;
        const events = geoLocationManager.GeofenceTransitionEvent;
        if (event === events.GEOFENCE_TRANSITION_EVENT_ENTER) {
          WorkoutSessionState.startTracking(String(transition.geofenceId), poi.name, nowMs);
        } else if (event === events.GEOFENCE_TRANSITION_EVENT_EXIT) {
          WorkoutSessionState.completeTracking(nowMs);
        }
      }
    );
    GeofenceRegistry.register(registered.geofenceId, poi.name);
    this.registeredGeofence = registered;
    this.statusMessage = `Geofence registered for ${poi.name}.`;
  }
}
