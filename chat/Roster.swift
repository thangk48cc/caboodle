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
    
//    func load(callback:(Bool) -> Void) {
//        Rest.sharedInstance.getRoster( {
//            if $0 != nil {
//                print("Roster load " + String($0))
//                let list = $0! as [String]
//                self.contacts = list.map({ Contact(username: "somebody", displayName: $0) });
//                callback(true)
//            } else {
//                callback(false)
//            }
//        })
//    }

    func set(friends:[String]?) {
        if let buds = friends {
            self.contacts = buds.map({ Contact(username: "somebody", displayName: $0) })
        } else {
            self.contacts.removeAll()
        }
    }
}