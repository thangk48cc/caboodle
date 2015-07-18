import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!

    @IBAction func login(sender: AnyObject) {
        Login.sharedInstance.login(username.text!, password: password.text!)

    }
    @IBAction func signup(sender: AnyObject) {
        Login.sharedInstance.register(username.text!, password: password.text!)
    }
}
