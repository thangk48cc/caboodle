import Foundation

class Rest {
    
    //let serverAddress = "http://127.0.0.1:3000/"
    let serverAddress = "http://45.55.12.220:3000/"
    
    var pushToken: String? = nil
    var reauthed: LoginCallback? = nil

    static let sharedInstance = Rest()
    
    typealias LoginCallback = (success:Bool, friends:[String]?) -> Void;
    
    func setPushToken(token:NSData) {
        self.pushToken = token.hexadecimalString
        self.reauth()
    }
    
    func register(username:String, password:String, callback:(success:Bool, friends:[String]?) -> Void) {
        return auth("register", username:username, password:password, callback:callback);
    }

    func login(username:String, password:String, callback:(success:Bool, friends:[String]?) -> Void) {
        return auth("login", username:username, password:password, callback:callback);
    }

    // wait for  push token, creds, and masterVC then reauth
    func reauth(callback:((success:Bool, friends:[String]?) -> Void)?=nil) {
        if callback != nil {
            self.reauthed = callback
        }
        if (self.reauthed == nil) || (self.pushToken == nil)  {
            return
        }
        guard let creds = Login.loadCredentials() else {
            print("missing creds in keychain")
            self.reauthed!(success:false, friends:nil)
            return
        }
        self.login(creds.username, password: creds.password, callback:self.reauthed!)
    }
    
    func auth(endpoint:String, username:String, password:String, callback:((success:Bool, friends:[String]?) -> Void)) {
        let credentials = ["username":username, "password":password, "pushToken":self.pushToken!]
        HttpHelper.post(credentials, url:serverAddress + endpoint, callback:{
            if ($0 == 200) || ($0 == 204) {
                Login.saveCredentials(username, password:password)
                let friends = $1 as! [String]
                callback(success:true, friends:friends);
            } else {
                callback(success:false, friends:nil);
            }
        })
    }

//    func getRoster(callback:(contacts:[String]?) -> Void) {
//        HttpHelper.get(nil, url:serverAddress+"roster", callback:{
//            if $0 == 200 {
//                let response = $1 as! [String]
//                callback(contacts: response)
//            } else {
//                callback(contacts: nil)
//            }
//        })
//    }
    
    func logout(callback:((success:Bool) -> Void)?=nil) {
        HttpHelper.get(nil, url:serverAddress+"logout", callback:{
            callback?(success:($0 == 204));
            $1;
        });
        
        do {
            try Locksmith.deleteDataForUserAccount("ClearKeep")
        } catch let error as NSError {
            print("could not remove from keychain: " + String(error))
        }
    }
    
    func befriend(friend:String, foreva:Bool, callback:(friends:[String]) -> Void) {
        
        let action = (foreva ? "add" : "del")
        HttpHelper.post(["username":friend, "action":action], url:serverAddress+"befriend", callback:{
            if $0 == 200 {
                callback(friends:$1 as! [String])
            }
        })
    }

    func send(recipient:String, message:String, callback:(success:Bool, message:String) -> Void) {
        HttpHelper.post(["addressee":recipient, "message":message], url:serverAddress+"send", callback:{
            $1; // noop
            callback(success:$0==204, message:message)
        })
    }
    
    // todo: store/load AnyObject
    func store(key:String, value:String, callback:((success:Bool) -> Void)?=nil) {
        HttpHelper.post(["key":key, "value":value], url:serverAddress+"send", callback:{
            $1; // noop
            callback?(success:$0==204)
        })
    }
    
    func load(key:String, callback:(value:String?) -> Void) {
        HttpHelper.get(nil, url:serverAddress+"load", callback:{
            if $0 == 200 {
                let response = $1 as! String
                callback(value: response)
            } else {
                callback(value: nil)
            }
        });
    }
}