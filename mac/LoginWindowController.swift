import Cocoa

class LoginWindowController: NSWindowController {

    @IBOutlet weak var username: NSTextField!
    @IBOutlet weak var password: NSTextField!

    @IBAction func signup(sender: AnyObject) {
        Login.sharedInstance.login(username.stringValue, password: password.stringValue)
    }
    
    @IBAction func login(sender: AnyObject) {
        Login.sharedInstance.register(username.stringValue, password: password.stringValue)
    }
}
