import Foundation

class Rest {
    
    let serverAddress = "http://project00-983.appspot.com/"
    
    static var session: String? = nil
    
    static let sharedInstance = Rest()
    
    typealias LoginCallback = (success:Bool) -> Void;

    func register(username:String, password:String, callback:(success:Bool) -> Void) {
        return auth("register", username:username, password:password, callback:callback);
    }

    func login(username:String, password:String, callback:(success:Bool) -> Void) {
        return auth("login", username:username, password:password, callback:callback);
    }

    func auth(endpoint:String, username:String, password:String, callback:(success:Bool) -> Void) {
        let credentials = ["username":username, "password":password]
        HttpHelper.post(credentials, url:serverAddress+endpoint, callback:{
            if $0 == 200 {
                let response = $1 as! [String:String];
                Rest.session = response["Session"]!
                callback(success: true);
            } else {
                callback(success: false);
            }
        })
    }

    func getRoster(callback:(contacts:[String:[[String:String]]]?) -> Void) {
        HttpHelper.get(nil, url:serverAddress+"roster" /*+Rest.session!*/, callback:{
            if $0 == 200 {
                let response = $1 as! [String:[[String:String]]]
                callback(contacts: response)
            } else {
                callback(contacts: nil)
            }
        })
    }
}