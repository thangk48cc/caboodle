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
    static let sharedInstance = Rest()
    var contacts = [Contact]()
    init() {}
    func load(callback:([String]?) -> Void) {
        Rest.sharedInstance.getRoster( {
            if $0 != nil {
                callback($0)
            }
        })
    }
}