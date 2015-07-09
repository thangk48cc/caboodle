import UIKit

class DetailViewController: UIViewController {

    var master: MasterViewController?
    var peer: Contact?

    
    @IBOutlet weak var bar: UINavigationItem!
    @IBOutlet weak var transcript: UITextView!
    @IBOutlet weak var entry: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bar.title = peer?.username
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.registerForKeyboardNotifications()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        self.deregisterFromKeyboardNotifications()
    }

    @IBAction func send(sender: AnyObject) {
        
        Rest.sharedInstance.send((peer?.username)!, message: entry.text!, callback: {
            if !$0 {
                print("error sending " + $1)
            }
        })
        
        transcript.text = transcript.text + "\nme: " + entry.text!
        entry.text?.removeAll()
    }
    
    @IBAction func unfriend(sender: AnyObject) {
        
        Rest.sharedInstance.befriend((peer?.username)!, foreva:false, callback: {
            self.master!.rosterUpdate($0)
        });
        navigationController!.popViewControllerAnimated(true)
    }
    
    func registerForKeyboardNotifications ()-> Void   {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWasShown:", name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillBeHidden:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func deregisterFromKeyboardNotifications () -> Void {
        let center:  NSNotificationCenter = NSNotificationCenter.defaultCenter()
        center.removeObserver(self, name: UIKeyboardDidHideNotification, object: nil)
        center.removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }

    func keyboardWasShown(notification: NSNotification) {
        
        let info : NSDictionary = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey]?.CGRectValue.size)!
        //let keyboardSize = info.objectForKey(UIKeyboardFrameBeginUserInfoKey)?.frame
        
//        let insets: UIEdgeInsets = UIEdgeInsetsMake(self.scrollView.contentInset.top, 0, keyboardSize.height, 0)
        
//        self.scrollView.contentInset = insets
//        self.scrollView.scrollIndicatorInsets = insets
//        
//        self.scrollView.contentOffset = CGPointMake(self.scrollView.contentOffset.x, self.scrollView.contentOffset.y + keyboardSize.height)
    }
    
    func keyboardWillBeHidden (notification: NSNotification) {
        
        let info : NSDictionary = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey]?.CGRectValue.size)!
//        let keyboardSize = info.objectForKey(UIKeyboardFrameBeginUserInfoKey)?.frame
        
//        let insets: UIEdgeInsets = UIEdgeInsetsMake(self.scrollView.contentInset.top, 0, keyboardSize.height, 0)
        
//        self.scrollView.contentInset = insets
//        self.scrollView.scrollIndicatorInsets = insets
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

