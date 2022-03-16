#import "EasyAppInstallerPlugin.h"
#if __has_include(<easy_app_installer/easy_app_installer-Swift.h>)
#import <easy_app_installer/easy_app_installer-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "easy_app_installer-Swift.h"
#endif

@implementation EasyAppInstallerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftEasyAppInstallerPlugin registerWithRegistrar:registrar];
}
@end
