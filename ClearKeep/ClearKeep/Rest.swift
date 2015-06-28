import Foundation

class Rest {
    
    let serverAddress = "http://127.0.0.1:3000/"
    
    static var session: String? = nil
    static var pushToken: String? = nil
    
    static let sharedInstance = Rest()
    
    typealias LoginCallback = (success:Bool) -> Void;

    static func setPushToken(token:NSData) {
        Rest.pushToken = token.hexadecimalString
    }
    
    func register(username:String, password:String, callback:(success:Bool) -> Void) {
        return auth("register", username:username, password:password, callback:callback);
    }

    func login(username:String, password:String, callback:(success:Bool) -> Void) {
        return auth("login", username:username, password:password, callback:callback);
    }

    func auth(endpoint:String, username:String, password:String, callback:(success:Bool) -> Void) {
        let credentials = ["username":username, "password":password, "pushToken":Rest.pushToken!]
        HttpHelper.post(credentials, url:serverAddress + endpoint, callback:{
            if $0 == 200 {
                let response = $1 as! [String:String];
                Rest.session = response["session"]!
                callback(success: true);
            } else {
                callback(success: false);
            }
        })
    }

    func getRoster(callback:(contacts:[[String:String]]?) -> Void) {
        HttpHelper.get(nil, url:serverAddress+"roster" /*+Rest.session!*/, callback:{
            if $0 == 200 {
                let response = $1 as! [[String:String]]
                callback(contacts: response)
            } else {
                callback(contacts: nil)
            }
        })
    }
}