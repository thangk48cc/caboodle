import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(aNotification: NSNotification) {

        // register for push notifications
        let application = aNotification.object
        let myTypes = NSRemoteNotificationType.Alert
        application?.registerForRemoteNotificationTypes(myTypes)
    }
    
    
    func application(application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        Rest.sharedInstance.setPushToken(deviceToken)
        print("Got token data! \(deviceToken)")
        Rest.sharedInstance.reauth()
    }
    
    func application(application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        Rest.sharedInstance.pushToken = "simulator"
        print("Couldn't register: \(error)")
        Rest.sharedInstance.reauth()
    }

    func application(application: NSApplication, didReceiveRemoteNotification userInfo: [String : AnyObject]) {
        NSLog("didReceiveRemoteNotification " + userInfo.description)
    }
}
