import Cocoa

class ViewController: NSViewController,NSTableViewDelegate {

    @IBOutlet weak var caller: NSButton!
    @IBOutlet var transcript: NSTextView!

    @IBAction func call(sender: AnyObject) {}
    
    @IBOutlet weak var entry: NSTextField!
    @IBOutlet weak var tableView: NSTableView!

    var mainW: NSWindow = NSWindow()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.setDelegate(self)

        Login.config(self, tableView:self.tableView)
        Login.sharedInstance.reauth()
    }
    
    override func viewDidAppear() {

//        let mdlwin = LoginPrompt(windowNibName: "LoginPrompt")
//        self.view.window?.beginSheet(mdlwin.window!, completionHandler:nil)
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

