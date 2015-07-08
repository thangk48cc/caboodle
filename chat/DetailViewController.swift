import UIKit

class DetailViewController: UIViewController {

    var master: MasterViewController?
    var peer: Contact?

    @IBOutlet weak var transcript: UITextView!
    @IBOutlet weak var entry: UITextField!
    @IBOutlet weak var bar: UINavigationItem!
    
    @IBAction func unfriend(sender: AnyObject) {
        
        Rest.sharedInstance.befriend((peer?.username)!, foreva:false, callback: {
            self.master!.rosterUpdate($0)
        });
 
        navigationController!.popViewControllerAnimated(true)
    }

    @IBAction func send(sender: AnyObject) {
        
        Rest.sharedInstance.send((peer?.username)!, message: entry.text!, callback: {
            if !$0 {
                print("error sending " + $1)
            }
        })

        transcript.text = transcript.text + "me: " + entry.text!
        entry.text?.removeAll()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.bar.title = peer?.username
        transcript.text = "some text"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

