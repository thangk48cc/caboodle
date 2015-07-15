import UIKit

class DetailViewController: UIViewController {

    var master: MasterViewController?
    var peer: Contact?
    var originalTranscriptFrame: CGRect?
    var originalEntryFrame: CGRect?

    static var theDetail : DetailViewController?
    
    @IBOutlet weak var bar: UINavigationItem!
    @IBOutlet weak var transcript: UITextView!
    @IBOutlet weak var entryBottom: NSLayoutConstraint!
    @IBOutlet weak var entry: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DetailViewController.theDetail = self
        self.bar.title = peer?.username
        Roster.sharedInstance.clear(peer!.username)
        self.entry.addTarget(self, action: "send:", forControlEvents: .EditingDidEndOnExit)
        
        Rest.sharedInstance.load((peer?.username)!, callback: {
            if let loaded = $0 {
                dispatch_async(dispatch_get_main_queue(),{
                    self.transcript.text = loaded
                })
            }
        })
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.registerForKeyboardNotifications()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        DetailViewController.theDetail = nil
        self.deregisterFromKeyboardNotifications()
    }

    @IBAction func send(sender: AnyObject) {
        
        Rest.sharedInstance.send((peer?.username)!, message: self.entry.text!, callback: {
            if !$0 {
                print("error sending " + $1)
            }
        })
        
        transcript.text = transcript.text + "\nme: " + self.entry.text!
        self.entry.text?.removeAll()
        
        Rest.sharedInstance.store((peer?.username)!, value: transcript.text)
    }
    
    func incoming(userInfo: [NSObject : AnyObject]) {
        NSLog("detail incoming " + String(userInfo.dynamicType) + " : " + userInfo.description)
        let from = userInfo["from"] as! String
        if from == self.peer?.username {
            let message = userInfo["message"] as! String
            let update = self.transcript.text + "\n" + from + ": " + message
            self.transcript.text = update
            Rest.sharedInstance.store((peer?.username)!, value: transcript.text)
        }
    }
    
    @IBAction func unfriend(sender: AnyObject) {
        
        Rest.sharedInstance.befriend((peer?.username)!, foreva:false, callback: {
            self.master!.rosterUpdate($0)
        });
        navigationController!.popViewControllerAnimated(true)
    }
    
    func registerForKeyboardNotifications ()-> Void   {
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWasShown:", name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillBeHidden:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func deregisterFromKeyboardNotifications () -> Void {
        let center:  NSNotificationCenter = NSNotificationCenter.defaultCenter()
        center.removeObserver(self, name: UIKeyboardDidHideNotification, object: nil)
        center.removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }

    func keyboardWillShow(notification: NSNotification) {
        self.updateBottomLayoutConstraintWithNotification(notification)
    }
    
    func updateBottomLayoutConstraintWithNotification(notification: NSNotification) {
        let info = notification.userInfo!
        
        let animationDuration = (info[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue)!
        let keyboardEndFrame = (info[UIKeyboardFrameEndUserInfoKey]?.CGRectValue)!
        let convertedKeyboardEndFrame = view.convertRect(keyboardEndFrame, fromView:view.window)
        let rawAnimationCurve = (info[UIKeyboardAnimationCurveUserInfoKey]?.unsignedIntegerValue)! << 16
        let animationCurve = UIViewAnimationOptions(rawValue:UInt(rawAnimationCurve))
        self.entryBottom.constant = CGRectGetMaxY(view.bounds) - CGRectGetMinY(convertedKeyboardEndFrame) + 10
        
        UIView.animateWithDuration(animationDuration, delay:0.0, options:[.BeginFromCurrentState, animationCurve], animations:{
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func keyboardWillBeHidden(notification: NSNotification) {
        NSLog("keyboardWillBeHidden")
        // todo
    }
}
