import { ArcListItem, ArcListItemAttribute } from '@kit.ArkUI';
import { RunPoi } from '../common/types';

/** Renders as a set of `ArcListItem`s — intended to be used directly as a child of an `ArcList`. */
@Component
export struct PoiListPanel {
  pois: RunPoi[] = [];
  selectedSiteId: string = '';
  onSelect: (poi: RunPoi) => void = () => {
  };

  build() {
    ForEach(this.pois, (poi: RunPoi) => {
      ArcListItem() {
        Column({ space: 2 }) {
          Text(poi.name)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .textAlign(TextAlign.Center)
            .maxLines(1)
          Text(poi.category.keyword + (poi.distanceMeters ? ` · ${Math.round(poi.distanceMeters)}m` : ''))
            .fontSize(9)
            .fontColor(Color.Gray)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding(6)
        .borderRadius(6)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(this.selectedSiteId === poi.siteId ? '#330A84FF' : Color.Transparent)
        .onClick(() => {
          this.onSelect(poi);
        })
      }
      .align(Alignment.Center)
    }, (poi: RunPoi) => poi.siteId)
  }
}
