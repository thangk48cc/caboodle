import UIKit

class LoginViewController: UIViewController,LoginDelegate {
    
    static var theLoginScreen : LoginViewController?
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        //add event textchagne for TextField username and password to enable or disable 2 button
        username.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged);
        password.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged);
        
        //add event click view to dismiss keyboad
        let touch = UITapGestureRecognizer(target: self, action: "handleTap");
        view.addGestureRecognizer(touch);
        
        //Login.sharedInstance.delegate = self;
    }
    
    func handleTap() {
        view.endEditing(true);
    }
    
    func textFieldDidChange(textField: UITextField) {
        validateInput();
    }
    
    
    //check Empty value in 2 textField
    func validateInput() {
        if (username.text != "" && password.text != "") {
            loginButton.enabled = true;
            loginButton.alpha = 1.0;
            signupButton.enabled = true;
            signupButton.alpha = 1.0;
        } else {
            loginButton.enabled = false;
            loginButton.alpha = 0.5;
            signupButton.enabled = false;
            signupButton.alpha = 0.5;
        }
    }
    
    func loginMessageError() {
        let alertView : UIAlertView;
        
        if (loginButton.selected) {
            alertView = UIAlertView(title: "Error Login", message: "Wrong username or password!", delegate: self, cancelButtonTitle: "OK");
        } else {
            alertView = UIAlertView(title: "Error Register", message: "Username is exist!", delegate: self, cancelButtonTitle: "OK");
        }
        
        alertView.show();
        
        //reset status button
        loginButton.selected = false;
        signupButton.selected = false;
    }
    
    @IBAction func login(sender: AnyObject) {
        loginButton.selected = true;
        signupButton.selected = false;
        Login.sharedInstance.login(username.text!, password: password.text!)
    }
    
    @IBAction func signup(sender: AnyObject) {
        loginButton.selected = false;
        signupButton.selected = true;
        Login.sharedInstance.register(username.text!, password: password.text!)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        LoginViewController.theLoginScreen = self
    }
}
