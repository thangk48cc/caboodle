import Foundation

class Contact {
    var displayName: String
    var username: String
    init(username:String, displayName:String) {
        self.username = username
        self.displayName = displayName
    }
}