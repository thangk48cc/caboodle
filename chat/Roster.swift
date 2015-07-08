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

    func set(friends:[String]?) {
        if let buds = friends {
            self.contacts = buds.map({ Contact(username: "somebody", displayName: $0) })
        } else {
            self.contacts.removeAll()
        }
    }
}