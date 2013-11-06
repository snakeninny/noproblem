#include <dlfcn.h>

// iOS 5
void *(*lockdown_connect)(void);
void (*lockdown_disconnect)(void *connection);
int (*lockdown_set_value)(void *connection, CFStringRef domain, CFStringRef key, CFPropertyListRef newValue);

// iOS 6
@interface MCProfileConnection : NSObject
+ (id)sharedConnection;
- (void)setBoolValue:(BOOL)arg1 forSetting:(id)arg2;
@end

static void DisableProblemSending(void)
{
	if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1)
	{
		void *libHandle = dlopen("/usr/lib/liblockdown.dylib", RTLD_LAZY);
		lockdown_connect = (void *(*)(void))dlsym(libHandle, "lockdown_connect");
		lockdown_disconnect = (void (*)(void *))dlsym(libHandle, "lockdown_disconnect");
		lockdown_set_value = (int (*)(void *, CFStringRef, CFStringRef, CFPropertyListRef))dlsym(libHandle, "lockdown_set_value");

		void *connection = lockdown_connect();
		lockdown_set_value(connection, (CFStringRef)@"com.apple.MobileDeviceCrashCopy", (CFStringRef)@"ShouldSubmit", kCFBooleanFalse);
		lockdown_set_value(connection, (CFStringRef)@"com.apple.MobileDeviceCrashCopy", (CFStringRef)@"ShouldSubmitVersion", (CFNumberRef)[NSNumber numberWithInt:1]);
		lockdown_disconnect(connection);
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)@"com.apple.OTACrashCopier.SubmissionPreferenceChanged", NULL, NULL, true);

		dlclose(libHandle);		
	}
	else if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_5_1 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1)
	{
		MCProfileConnection *connection = [%c(MCProfileConnection) sharedConnection];
		[connection setBoolValue:NO forSetting:@"allowDiagnosticSubmission"];
	}
}

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application
{
	%orig;

	DisableProblemSending();
}
%end
