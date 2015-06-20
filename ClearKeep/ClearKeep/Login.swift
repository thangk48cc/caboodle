import Foundation
import UIKit

class Login {
    
    var parent:UIViewController
    var callback:Callback

    init(parent:UIViewController, callback:Callback) {
        self.parent = parent;
        self.callback = callback;
    }
    
    typealias Callback = (success:Bool) -> Void;
    
    static func popup(parent:UIViewController, callback:Callback) {
        Login(parent:parent, callback:callback).challenge()
    }
    
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
            self.authenticate(credentials.username, password:credentials.password)
        }
        loginAction.enabled = false
        
        func configureTextField(textField:UITextField, placeholder:String) {
            textField.placeholder = placeholder
            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue()) { (notification) in
                let credentials = userInput();
                loginAction.enabled = credentials.username != "" && credentials.password != ""
            }
        }
        
        let createAccountAction = UIAlertAction(title: "Create Account", style: .Default) { (_) in }
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            configureTextField(textField, placeholder: "Username");
        }
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            configureTextField(textField, placeholder: "Password");
            textField.secureTextEntry = true
        }
        
        alertController.addAction(loginAction)
        alertController.addAction(createAccountAction)

        self.parent.presentViewController(alertController, animated: true, completion: nil);
    }
    
    func authenticate(username:String, password:String) {
    
        Rest.sharedInstance.login(username, password: password, callback: {
            if !$0 { // login failed
                self.callback(success:false)
                dispatch_async(dispatch_get_main_queue(),{
                    self.challenge()
                })
            }
            self.callback(success: true)
        })
    }
}