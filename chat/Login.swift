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

    static func popup(parent:ParentViewController, tableView:ParentTableView) {
        dispatch_async(dispatch_get_main_queue(),{
            Login.config(parent, tableView:tableView)
            Login.sharedInstance.challenge()
        })
    }

    func authenticated(success:Bool, friends:[String]?) {
        if !success { // login failed
            dispatch_async(dispatch_get_main_queue(),{
                self.challenge()
            })
        }
  
        Roster.sharedInstance.set(friends)
        self.tableView?.reloadData()
    }

    func register(username:String, password:String) {
        Rest.sharedInstance.register(username, password:password, pushToken:self.pushToken!, callback:authenticated)
    }

    func login(username:String, password:String) {
        Rest.sharedInstance.login(username, password: password, pushToken:self.pushToken!, callback:authenticated)
    }

    func reauth() {
        if self.pushToken == nil || self.parent == nil {
            return
        }
        guard let creds = Login.loadCredentials() else {
            print("missing creds in keychain")
            Login.sharedInstance.reauthed(false, friends:nil)
            return
        }
        self.login(creds.username, password: creds.password)
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
    
    func reauthed(success:Bool, friends:[String]?) {
        if success {
            Roster.sharedInstance.set(friends)
            self.tableView?.reloadData()
        } else {
            self.challenge()
        }
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

    // popup the login alert
    func challenge() {
        
        let alertController = UIAlertController(title: "Welcome to Chat", message: "Enter your credentials", preferredStyle: .Alert)
        
        func userInput() -> (username:String, password:String) {
            let username = alertController.textFields![0].text
            let password = alertController.textFields![1].text
            return (username!, password!);
        }
        
        let loginAction = UIAlertAction(title: "Login", style: .Default) { (_) in
            let credentials = userInput();
            self.login(credentials.username, password:credentials.password)
        }
        loginAction.enabled = false
        
        let registerAction = UIAlertAction(title: "Create Account", style: .Default) { (_) in
            let credentials = userInput();
            self.register(credentials.username, password:credentials.password)
        }
        registerAction.enabled = false
        
        func configureTextField(textField:UITextField, placeholder:String) {
            textField.placeholder = placeholder
            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue()) { (notification) in
                let credentials = userInput();
                let enabled = credentials.username != "" && credentials.password != ""
                loginAction.enabled = enabled
                registerAction.enabled = enabled
            }
        }
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            configureTextField(textField, placeholder: "Username");
        }
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            configureTextField(textField, placeholder: "Password");
            textField.secureTextEntry = true
        }
        
        alertController.addAction(loginAction)
        alertController.addAction(registerAction)
        
        self.parent!.presentViewController(alertController, animated: true, completion: nil);
    }
}

#endif

#if os(OSX)
    
extension Login {

    // popup the login alert
    func challenge() {
        
    }
}
    
#endif
