

#if os(iOS)

    import UIKit
    
    class LoginPrompt: UIViewController {
        @IBOutlet weak var username: UITextField!
        @IBOutlet weak var password: UITextField!

        @IBAction func login(sender: AnyObject) {
            Login.sharedInstance.login(username.text!, password: password.text!)
        }
        
        @IBAction func signup(sender: AnyObject) {
            Login.sharedInstance.register(username.text!, password: password.text!)
        }
    }

#endif

#if os(OSX)

    import Cocoa

    class LoginPrompt: NSWindowController {
    
        @IBOutlet weak var username: NSTextField!
        @IBOutlet weak var password: NSTextField!

        @IBAction func login(sender: AnyObject) {
        Login.sharedInstance.login(username.stringValue, password: password.stringValue)
        }
        
        @IBAction func signup(sender: AnyObject) {
        Login.sharedInstance.register(username.stringValue, password: password.stringValue)
        }
    }

#endif




