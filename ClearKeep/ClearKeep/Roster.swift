import Foundation

class Contact {
    var displayName: String
    var username: String
    init(username:String, displayName:String) {
        self.username = username
        self.displayName = displayName
    }
}

class Roster {

    static let sharedInstance = Roster()
    
    var contacts = [Contact]()
    init() {}
    
    func load(callback:(Bool) -> Void) {
        Rest.sharedInstance.getRoster( {
            if $0 != nil {
                print($0)
                let response = $0! as [String:[[String:String]]];
                let list = response["Contacts"]!
                self.contacts = list.map({ Contact(username: $0["Username"]!, displayName: $0["Displayname"]!) });
                callback(true)
            } else {
                callback(false)
            }
        })
    }
}