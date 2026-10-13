#import <Foundation/Foundation.h>
#import <NetworkExtension/NetworkExtension.h>

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
            SJVLog(@"Requested StosVPN connection. iOS entitlement/profile checks may still reject the request.");
        }];
    }
}

%ctor {
    @autoreleasepool {
        NSString *bundleID = NSBundle.mainBundle.bundleIdentifier ?: @"";
        if ([bundleID isEqualToString:@"com.stik.stikdebug"]) {
            SJVLog(@"Loaded into StikDebug; scheduling VPN auto-start.");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                SJVStartStosVPN();
            });
        }
    }
}
