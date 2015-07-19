import UIKit

class LoginViewController: UIViewController {

    static var theLoginScreen : LoginViewController?
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!

    @IBAction func login(sender: AnyObject) {
        Login.sharedInstance.login(username.text!, password: password.text!)

    }
    @IBAction func signup(sender: AnyObject) {
        Login.sharedInstance.register(username.text!, password: password.text!)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        LoginViewController.theLoginScreen = self
    }
}
