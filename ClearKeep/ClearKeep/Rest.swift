import Foundation

class Rest {
    
    let serverAddress = "http://127.0.0.1:8000/"
    
    static var session: String? = nil
    
    static let sharedInstance = Rest()
    
    typealias LoginCallback = (success:Bool) -> Void;
    
    func login(username:String, password:String, callback:(success:Bool) -> Void) {
        let credentials = ["username":username, "password":password]
        HttpHelper.post(credentials, url:serverAddress+"login", callback:{
            if $0 == 200 {
                let response = $1 as! [String:String];
                Rest.session = response["Session"]!
                callback(success: true);
            } else {
                callback(success: false);
            }
        })
    }
    
    func getRoster(callback:(contacts:[String]?) -> Void) {
        HttpHelper.post(nil, url:serverAddress+"roster/"+Rest.session!, callback:{
            if $0 == 200 {
                let response = $1 as! [String]
                callback(contacts: response)
            } else {
                callback(contacts: nil)
            }
        })
    }
}