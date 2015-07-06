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
                print("Roster load " + String($0))
                let list = $0! as [[String:String]]
                self.contacts = list.map({ Contact(username: $0["id"]!, displayName: $0["name"]!) });
                callback(true)
            } else {
                callback(false)
            }
        })
    }
    
    func befriend(friend:String) {
        Rest.sharedInstance.befriend(friend, callback:{
            if !$0 {
                print("could not add " + friend)
            }
        })
    }
}