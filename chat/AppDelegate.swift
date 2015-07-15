import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        if let notification = launchOptions?[UIApplicationLaunchOptionsLocalNotificationKey] as! UILocalNotification! {
            NSLog("local notification " + notification.description)
        } else if let notification = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] as! NSDictionary! {
            NSLog("remote notification " + notification.description)
        }
        
        // set up UI
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
        splitViewController.delegate = self

        // register for push
        UIApplication.sharedApplication().registerForRemoteNotifications()
        let settings = UIUserNotificationSettings(forTypes: .Alert, categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)

        HttpHelper.monitorReachability(Rest.sharedInstance.serverAddress)
        
        return true
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        Rest.sharedInstance.setPushToken(deviceToken)
        print("Got token data! \(deviceToken)")
        Rest.sharedInstance.reauth()
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        Rest.sharedInstance.pushToken = "simulator"
        print("Couldn't register: \(error)")
        Rest.sharedInstance.reauth()
    }

    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        // inspect notificationSettings to see what the user said
//        let settings = UIApplication.sharedApplication().currentUserNotificationSettings()
//        print("notification settings = " + settings!.description)
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {

        NSLog("didReceiveRemoteNotification " + userInfo.description)
        
        if application.applicationState == UIApplicationState.Inactive || application.applicationState == UIApplicationState.Background {
            NSLog("\topened from a remote push notification when the app was on background: " + userInfo.description)
        } else {
            MasterViewController.theMaster?.incoming(userInfo)
            DetailViewController.theDetail?.incoming(userInfo)
        }
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        NSLog("didReceiveRemoteNotification " + notification.description)
        if application.applicationState == UIApplicationState.Inactive || application.applicationState == UIApplicationState.Background {
            //opened from a push notification when the app was on background
            NSLog("\topened from a local push notification when the app was on background")
        }
    }

    // MARK: - Split view

    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController else { return false }
        if topAsDetailController.peer == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }

}

