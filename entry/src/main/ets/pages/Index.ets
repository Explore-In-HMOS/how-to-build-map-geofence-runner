import { common } from '@kit.AbilityKit';
import { MapRunnerView } from '../components/MapRunnerView';
import { PermissionService } from '../services/PermissionService';

/**
 * Entry page. Requests location permissions on launch (before the map/POI/
 * geofence flows mount), showing a lightweight splash while the request is in
 * flight, then swaps to the map runner view. Modelled as conditional rendering
 * within a single entry page rather than a separate page + page navigation.
 */
@Entry
@Component
struct Index {
  @State private ready: boolean = false;
  @State private statusText: string = 'Requesting location access...';
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;

  aboutToAppear(): void {
    this.requestPermissionsThenContinue();
  }

  build() {
    Stack() {
      if (this.ready) {
        MapRunnerView()
      } else {
        Column({ space: 12 }) {
          LoadingProgress()
            .width(48)
            .height(48)
            .color(Color.White)
          Text(this.statusText)
            .fontSize(11)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .width('80%')
        }
        .width('100%')
        .height('100%')
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Color.Black)
      }
    }
    .width('100%')
    .height('100%');
  }

  private async requestPermissionsThenContinue(): Promise<void> {
    try {
      const granted = await PermissionService.ensureLocationPermissions(this.context);
      this.statusText = granted
        ? 'Location access granted.'
        : 'Location permission denied — continuing with limited features.';
    } catch (error) {
      this.statusText = 'Unable to request permissions — continuing.';
    } finally {
      this.ready = true;
    }
  }
}
