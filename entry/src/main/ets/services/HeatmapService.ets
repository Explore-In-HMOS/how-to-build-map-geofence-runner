import { map, mapCommon } from '@kit.MapKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { RunHistoryPoint } from '../common/types';

const HEATMAP_OVERLAY_ID = 'run-frequency-heatmap';
const MOCK_HISTORY_POINT_COUNT = 6;
const MOCK_HISTORY_SPREAD_DEGREES = 0.01;

const secureRng: cryptoFramework.Random = cryptoFramework.createRandom();

/** Cryptographically-secure replacement for Math.random(): a float in [0, 1). */
function secureRandom(rng: cryptoFramework.Random): number {
  const bytes: Uint8Array = rng.generateRandomSync(4).data;
  const value: number = ((bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3]) >>> 0;
  return value / 0x100000000;
}

export class HeatmapService {
  /**
   * Local mock run-history data (coordinate + frequency weight), standing in for a
   * real run-history store so the heat map flow is demoable without a backend.
   */
  static getMockRunHistory(center: mapCommon.LatLng): RunHistoryPoint[] {
    const points: RunHistoryPoint[] = [];
    for (let i = 0; i < MOCK_HISTORY_POINT_COUNT; i++) {
      const offsetLat = (secureRandom(secureRng) - 0.5) * MOCK_HISTORY_SPREAD_DEGREES;
      const offsetLng = (secureRandom(secureRng) - 0.5) * MOCK_HISTORY_SPREAD_DEGREES;
      points.push({
        location: {
          latitude: center.latitude + offsetLat,
          longitude: center.longitude + offsetLng
        },
        frequency: 1 + Math.floor(secureRandom(secureRng) * 8)
      });
    }
    return points;
  }

  /** Expands weighted history points into MassPointItems (repeated per frequency) for density. */
  private static toMassPointItems(history: RunHistoryPoint[]): mapCommon.MassPointItem[] {
    const items: mapCommon.MassPointItem[] = [];
    history.forEach((point: RunHistoryPoint, index: number) => {
      for (let repeat = 0; repeat < point.frequency; repeat++) {
        items.push({
          itemId: `${HEATMAP_OVERLAY_ID}-${index}-${repeat}`,
          position: point.location
        });
      }
    });
    return items;
  }

  static async renderHeatmap(
    controller: map.MapComponentController,
    history: RunHistoryPoint[],
    icon: Resource
  ): Promise<map.MassPointOverlay> {
    const params: mapCommon.MassPointOverlayParams = {
      id: HEATMAP_OVERLAY_ID,
      items: HeatmapService.toMassPointItems(history),
      icon
    };
    return controller.addMassPointOverlay(params);
  }
}
