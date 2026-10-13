#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <NetworkExtension/NetworkExtension.h>
#import <objc/runtime.h>

static BOOL SJVStarted = NO;

static void SJVLog(NSString *message) {
    NSLog(@"[StikJITVPN] %@", message);
}

static void SJVStartStosVPN(void) {
    @autoreleasepool {
        if (SJVStarted) return;
        SJVStarted = YES;
        SJVLog(@"Looking for an installed StosVPN tunnel profile.");

        [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
            if (error) {
                SJVLog([NSString stringWithFormat:@"Could not load VPN profiles: %@", error.localizedDescription]);
                return;
            }

            NETunnelProviderManager *match = nil;
            for (NETunnelProviderManager *manager in managers ?: @[]) {
                NETunnelProviderProtocol *proto = (NETunnelProviderProtocol *)manager.protocolConfiguration;
                NSString *bundleID = proto.providerBundleIdentifier ?: @"";
                if ([bundleID rangeOfString:@"StosVPN" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                    [bundleID rangeOfString:@"TunnelProv" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    match = manager;
                    break;
                }
            }

            if (!match) {
                SJVLog(@"No StosVPN profile found. Install and configure StosVPN first.");
                return;
            }
            if (!match.isEnabled) {
                SJVLog(@"StosVPN profile is disabled; enable it in Settings first.");
                return;
            }

            NEVPNStatus status = match.connection.status;
            if (status == NEVPNStatusConnected || status == NEVPNStatusConnecting || status == NEVPNStatusReasserting) {
                SJVLog(@"StosVPN is already connected or connecting.");
                return;
            }

            NSError *startError = nil;
            if (![match.connection startVPNTunnelAndReturnError:&startError]) {
                SJVLog([NSString stringWithFormat:@"VPN start failed: %@", startError.localizedDescription ?: @"unknown error"]);
                return;
            }
            SJVLog(@"Requested StosVPN connection. iOS may require user approval or a valid VPN profile.");
        }];
    }
}

%group StikJITVPNAutoStart
%hook UIApplication
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    BOOL result = %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        SJVStartStosVPN();
    });
    return result;
}
%end
%end

%ctor {
    @autoreleasepool {
        NSString *bundleID = NSBundle.mainBundle.bundleIdentifier ?: @"";
        if ([bundleID isEqualToString:@"com.stik.stikdebug"]) {
            %init(StikJITVPNAutoStart);
            SJVLog(@"Loaded into StikDebug; VPN auto-start will run at app launch.");
        }
    }
}
