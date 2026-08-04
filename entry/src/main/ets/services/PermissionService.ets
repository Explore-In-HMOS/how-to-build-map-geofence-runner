import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit';

const REQUIRED_PERMISSIONS: Permissions[] = [
  'ohos.permission.LOCATION',
  'ohos.permission.APPROXIMATELY_LOCATION',
  'ohos.permission.LOCATION_IN_BACKGROUND'
];

export class PermissionService {
  static async ensureLocationPermissions(context: common.UIAbilityContext): Promise<boolean> {
    if (await PermissionService.allGranted()) {
      return true;
    }
    const atManager = abilityAccessCtrl.createAtManager();
    const result = await atManager.requestPermissionsFromUser(context, REQUIRED_PERMISSIONS);
    return result.authResults.every(
      (status: number) => status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
    );
  }

  private static async allGranted(): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    const bundleInfo = await bundleManager.getBundleInfoForSelf(
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
    );
    const tokenId = bundleInfo.appInfo.accessTokenId;
    for (const permission of REQUIRED_PERMISSIONS) {
      const status = await atManager.checkAccessToken(tokenId, permission);
      if (status !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        return false;
      }
    }
    return true;
  }
}
