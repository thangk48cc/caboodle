import Foundation

class Contact {

    var displayName: String
    var username: String
    var unread = 0
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
            self.contacts = buds.map({ Contact(username: $0, displayName: $0) })
        } else {
            self.contacts.removeAll()
        }
    }
    
    func increment(username:String) {
        if let index = self.contacts.indexOf({$0.username == username}) {
            contacts[index].unread++
        } else {
            NSLog("Roster - could not increment " + username)
        }
    }
    
    func clear(username:String) {
        if let index = self.contacts.indexOf({$0.username == username}) {
            contacts[index].unread = 0
        } else {
            NSLog("Roster - could not clear " + username)
        }
    }
}