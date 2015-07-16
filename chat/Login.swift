#if os(iOS)
import UIKit
typealias ParentViewController = UIViewController
#endif
#if os(OSX)
import Cocoa
typealias ParentViewController = NSViewController
#endif

class Login {

    var parent:ParentViewController?
    var callback:Callback?

    private static var loginInstance: Login?

    init(parent:ParentViewController, callback:Callback) {
        self.parent = parent
        self.callback = callback
    }
    
    class func config(parent:ParentViewController, callback:Callback) -> Login {
        loginInstance = Login(parent: parent, callback:callback)
        return loginInstance!
    }

    class var sharedInstance: Login {
        if loginInstance == nil {
            print("error: shared called before setup")
        }
        return loginInstance!
    }
    
    typealias Callback = (success:Bool, friends:[String]?) -> Void;

    static func popup(parent:ParentViewController, callback:Callback) {
        dispatch_async(dispatch_get_main_queue(),{
            Login.config(parent, callback:callback).challenge()
        })
    }

    func authenticated(success:Bool, friends:[String]?) {
        if !success { // login failed
            self.callback!(success:false, friends:nil)
            dispatch_async(dispatch_get_main_queue(),{
                self.challenge()
            })
        }
            
        self.callback!(success:true, friends:friends)
    }

    func register(username:String, password:String) {
        Rest.sharedInstance.register(username, password: password, callback:authenticated)
    }

    func login(username:String, password:String) {
        Rest.sharedInstance.login(username, password: password, callback:authenticated)
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
