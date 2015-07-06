import UIKit

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil

    //@IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //self.navigationItem.leftBarButtonItem = self.editButtonItem()
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
    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)

        Rest.sharedInstance.reauth(reauthed)
    }
    
    func reauthed(success:Bool) {
  
        if !success {
            self.loginPopup()
        }
    }

    func loginPopup() {
        Login.popup(self.parentViewController!, callback: {
            if $0 {
                Roster.sharedInstance.load( {
                    print("roster loaded " + String($0))
                    dispatch_async(dispatch_get_main_queue(),{
                        self.tableView.reloadData();
                    })
                })
            }
        });
    }

    func logout(sender: AnyObject) {
        Rest.sharedInstance.logout()
        self.loginPopup()
    }

    func insertNewObject(sender: AnyObject) {
        Roster.sharedInstance.contacts.insert(Contact(username:"x", displayName:"y"), atIndex: 0)
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = Roster.sharedInstance.contacts[indexPath.row]
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
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
        cell.textLabel!.text = Roster.sharedInstance.contacts[indexPath.row].displayName
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
