#import <Cocoa/Cocoa.h>
#import <Sparkle/Sparkle.h>

static void record(NSString *event) {
    NSString *path = [NSBundle.mainBundle objectForInfoDictionaryKey:@"TestLog"];
    NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:path];
    [file seekToEndOfFile];
    [file writeData:[[event stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [file closeFile];
}

@interface Driver : NSObject <NSApplicationDelegate, SPUUserDriver>
@property SPUUpdater *updater;
@end
@implementation Driver
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    if ([[NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"] isEqual:@"2"]) {
        record(@"relaunched-version-2");
        [NSApp terminate:nil];
        return;
    }
    self.updater = [[SPUUpdater alloc] initWithHostBundle:NSBundle.mainBundle applicationBundle:NSBundle.mainBundle userDriver:self delegate:nil];
    NSError *error = nil;
    if (![self.updater startUpdater:&error]) { record(error.description); exit(1); }
    [self.updater checkForUpdates];
}
- (void)showUpdatePermissionRequest:(SPUUpdatePermissionRequest *)request reply:(void (^)(SUUpdatePermissionResponse *))reply {
    reply([[SUUpdatePermissionResponse alloc] initWithAutomaticUpdateChecks:NO sendSystemProfile:NO]);
}
- (void)showUserInitiatedUpdateCheckWithCancellation:(void (^)(void))cancellation { record(@"checking"); }
- (void)showUpdateFoundWithAppcastItem:(SUAppcastItem *)item state:(SPUUserUpdateState *)state reply:(void (^)(SPUUserUpdateChoice))reply {
    record(@"update-found");
    if ([[NSBundle.mainBundle objectForInfoDictionaryKey:@"TestCancel"] boolValue]) {
        record(@"cancelled"); reply(SPUUserUpdateChoiceDismiss); [NSApp terminate:nil];
    } else {
        reply(SPUUserUpdateChoiceInstall);
    }
}
- (void)showUpdateReleaseNotesWithDownloadData:(SPUDownloadData *)data {}
- (void)showUpdateReleaseNotesFailedToDownloadWithError:(NSError *)error {}
- (void)showUpdateNotFoundWithError:(NSError *)error acknowledgement:(void (^)(void))reply {
    record(@"no-update"); reply(); [NSApp terminate:nil];
}
- (void)showUpdaterError:(NSError *)error acknowledgement:(void (^)(void))reply {
    record([@"error: " stringByAppendingString:error.description]); reply(); [NSApp terminate:nil];
}
- (void)showDownloadInitiatedWithCancellation:(void (^)(void))cancellation { record(@"downloading"); }
- (void)showDownloadDidReceiveExpectedContentLength:(uint64_t)length {}
- (void)showDownloadDidReceiveDataOfLength:(uint64_t)length {}
- (void)showDownloadDidStartExtractingUpdate { record(@"extracting"); }
- (void)showExtractionReceivedProgress:(double)progress {}
- (void)showReadyToInstallAndRelaunch:(void (^)(SPUUserUpdateChoice))reply { record(@"installing"); reply(SPUUserUpdateChoiceInstall); }
- (void)showInstallingUpdateWithApplicationTerminated:(BOOL)terminated retryTerminatingApplication:(void (^)(void))retry {}
- (void)showUpdateInstalledAndRelaunched:(BOOL)relaunched acknowledgement:(void (^)(void))reply { reply(); }
- (void)dismissUpdateInstallation {}
@end

int main(void) {
    @autoreleasepool {
        Driver *driver = [Driver new];
        NSApplication.sharedApplication.delegate = driver;
        [NSApplication.sharedApplication run];
    }
    return 0;
}
