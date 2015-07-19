#if os(iOS)
import UIKit
typealias ParentViewController = UIViewController
typealias ParentTableView = UITableView
#endif
#if os(OSX)
import Cocoa
typealias ParentViewController = NSViewController
typealias ParentTableView = NSTableView
#endif

/*
 *  Login
 *
 *  flow:
 *      1) App UI launches, saves controller and tableView in Login.sharedInstance.config()
 *      2) AppDelegate gets push token, saves in Login.sharedInstance.setPushToken(), then calls .reauth()
 *      3) .reauth() loads creds, makes HTTP POST, calls .authenticated() with result
 *      4) .authenticated() either loads the contact list into UI if success, else calls .challenge()
 */
class Login {

    var parent:ParentViewController?
    var tableView:ParentTableView?
    var pushToken: String?

    static let sharedInstance = Login()

    func setPushToken(token:NSData) {
        self.pushToken = token.hexadecimalString
    }
    
    class func config(parent:ParentViewController, tableView:ParentTableView) {
        Login.sharedInstance.parent = parent
        Login.sharedInstance.tableView = tableView
    }

    func reauth() {
        if self.pushToken == nil || self.parent == nil {
            return
        }
        guard let creds = Login.loadCredentials() else {
            print("missing creds in keychain")
            self.challenge()
          return
        }
        self.login(creds.username, password: creds.password)
    }

    func register(username:String, password:String) {
        Rest.sharedInstance.register(username, password:password, pushToken:self.pushToken!, callback:authenticated)
    }

    func login(username:String, password:String) {
        Rest.sharedInstance.login(username, password: password, pushToken:self.pushToken!, callback:authenticated)
    }

    func authenticated(success:Bool, friends:[String]?) {

        if success {
            self.welcome()
        } else {
            dispatch_async(dispatch_get_main_queue(),{
                self.challenge()
            })
        }
        
        Roster.sharedInstance.set(friends)
        self.tableView?.reloadData()
    }

    static func saveCredentials(username:String, password:String) {
        do {
            try Locksmith.updateData(["username": username, "password": password], forUserAccount: "ClearKeep")
        } catch let error as NSError {
            print("could not save to keychain: " + String(error))
        }
    }
    
    static func loadCredentials() -> (username: String, password: String)? {
        guard let creds = Locksmith.loadDataForUserAccount("ClearKeep") else {
            print("could not load from keychain")
            return nil
        }
        guard let u = creds["username"], p = creds["password"] else {
            return nil
        }
        return (u as! String, p as! String)
    }

    func logout() {
        
        Rest.sharedInstance.logout()
        do {
            try Locksmith.deleteDataForUserAccount("ClearKeep")
        } catch let error as NSError {
            print("could not remove from keychain: " + String(error))
        }
        
        self.challenge()
    }
}

#if os(iOS)

extension Login {

    func challenge() {
        dispatch_async(dispatch_get_main_queue(),{
            self.parent!.performSegueWithIdentifier("LoginSegue", sender: nil)
        })
    }
    
    func welcome() {
        LoginViewController.theLoginScreen?.dismissViewControllerAnimated(true, completion:nil)
    }
}

#endif

#if os(OSX)
    
extension Login {

    func challenge() {
        let lp = LoginWindowController(windowNibName: "LoginWindowController")
        let passwordSheet = lp.window!
        let iret = NSApplication.sharedApplication().runModalForWindow(passwordSheet)
        NSLog("password dialog returned = %ld", iret);
    }

    func welcome() {
        LoginWindowController.theLoginScreen?.close()
    }
}

#endif
