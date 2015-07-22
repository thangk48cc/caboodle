import Cocoa

class ViewController: NSViewController,NSTableViewDelegate {

    var peer : Contact?

    @IBOutlet weak var caller: NSButton!
    @IBOutlet var transcript: NSTextView!

    @IBAction func call(sender: AnyObject) {}
    @IBAction func sendText(sender: AnyObject) {
        Rest.sharedInstance.send(self.peer!.username, message: self.entry.stringValue, callback: {
            if !$0 {
                print("error sending " + $1)
            }
        })
    }
    
    @IBOutlet weak var entry: NSTextField!
    @IBOutlet weak var tableView: NSTableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        Login.config(self, tableView:self.tableView)
        Login.sharedInstance.reauth()
    }
    
    func tableViewSelectionDidChange(notification:NSNotification) {

        let row = self.tableView.selectedRow
        self.peer = Roster.sharedInstance.contacts[row]
        Rest.sharedInstance.load(peer!.username, callback: {
            if let loaded = $0 {
                dispatch_async(dispatch_get_main_queue(),{
                    self.transcript.string = loaded
                })
            }
        })
    }
}

extension ViewController: NSTableViewDataSource {

    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        return Roster.sharedInstance.contacts.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {

        let cell = tableView.makeViewWithIdentifier(tableColumn!.identifier, owner: self) as! NSTableCellView

        let contact = Roster.sharedInstance.contacts[row]
        let unread = contact.unread == 0 ? "" : " (" + String(contact.unread) + ")"
        cell.textField!.stringValue = contact.displayName + unread
        cell.textField!.textColor = NSColor.orangeColor()

        return cell
    }
}

class CellView: NSTableCellView {
    
    override var backgroundStyle: NSBackgroundStyle {
        set {
            if let rowView = self.superview as? NSTableRowView {
                super.backgroundStyle = rowView.selected ? NSBackgroundStyle.Dark : NSBackgroundStyle.Light
            } else {
                super.backgroundStyle = newValue
            }
            self.udpateSelectionHighlight()
        }
        get {
            return super.backgroundStyle;
        }
    }
    
    func udpateSelectionHighlight() {
        if ( self.backgroundStyle == NSBackgroundStyle.Dark ) {
            self.textField?.textColor = NSColor.whiteColor()
        } else {
            self.textField?.textColor = NSColor.blackColor()
        }
    }
    
}

