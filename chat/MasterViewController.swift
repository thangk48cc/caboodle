import UIKit

class MasterViewController: UITableViewController {

    static var theMaster : MasterViewController?

    var detailViewController: DetailViewController? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        let logoutButton = UIBarButtonItem(title:"Logout", style:UIBarButtonItemStyle.Plain, target:self, action:"logout:")
        self.navigationItem.leftBarButtonItem = logoutButton
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        self.tableView.backgroundView = nil;
        self.tableView.backgroundColor = UIColor.blackColor();
        
        Login.config(self, tableView:self.tableView)
        Login.sharedInstance.reauth()
    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
        MasterViewController.theMaster = self
        Login.sharedInstance.reauth()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        MasterViewController.theMaster = nil
    }

    func logout(sender: AnyObject) {
        Login.sharedInstance.logout()
    }
    
    func insertNewObject(sender: AnyObject) {
        let alertController = UIAlertController(title: "Add a friend", message: "Enter your friend's username'", preferredStyle: .Alert)
    
        func userInput() -> String {
            return alertController.textFields![0].text!
        }

        let befriendAction = UIAlertAction(title: "Add", style: .Default) { (_) in
            let username = userInput();
            Rest.sharedInstance.befriend(username, foreva:true, tableView:self.tableView);
        }
        befriendAction.enabled = false
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in }
        
        func configureTextField(textField:UITextField, placeholder:String) {
            textField.placeholder = placeholder
            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue()) { (notification) in
                let enabled = userInput() != ""
                befriendAction.enabled = enabled
            }
        }

        alertController.addTextFieldWithConfigurationHandler { (textField) in
            configureTextField(textField, placeholder: "Username");
        }
        alertController.addAction(befriendAction)
        
        self.presentViewController(alertController, animated: true, completion: nil);
    }

    
    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showDetail" {

            var row = -1

            if (sender!.isKindOfClass(UITableViewCell)) {
                row = (self.tableView.indexPathForSelectedRow?.row)!
            } else if (sender!.isKindOfClass(NSIndexPath)) {
                row = sender!.row
            } else {
                assert(false)
            }

            let object = Roster.sharedInstance.contacts[row]
            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
            controller.master = self
            controller.peer = object
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
            controller.navigationItem.leftItemsSupplementBackButton = true
        }
    }

    func incoming(userInfo: [NSObject : AnyObject]) {
        NSLog("Master incoming " + String(userInfo.dynamicType) + " : " + userInfo.description)
        let from = userInfo["from"] as! String
        if from != self.detailViewController?.peer?.username { // not current conversation
            Roster.sharedInstance.increment(from)
            self.tableView.reloadData()
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("# rows: " + Roster.sharedInstance.contacts.count)
        return Roster.sharedInstance.contacts.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        let contact = Roster.sharedInstance.contacts[indexPath.row]
        let unread = contact.unread == 0 ? "" : " (" + String(contact.unread) + ")"
        cell.textLabel!.text = contact.displayName + unread
        cell.textLabel!.textColor = UIColor.orangeColor()
        cell.backgroundColor = UIColor.blackColor()
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            Roster.sharedInstance.contacts.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
}

