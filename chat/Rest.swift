import Foundation

class Rest {
    
    // let serverAddress = "http://127.0.0.1:3000/"
    let serverAddress = "http://45.55.12.220:3000/"
    
    var pushToken: String? = nil
    var session: String? = nil
    var reauthed: LoginCallback? = nil

    static let sharedInstance = Rest()
    
    typealias LoginCallback = (success:Bool) -> Void;
    
    func setPushToken(token:NSData) {
        self.pushToken = token.hexadecimalString
        self.reauth()
    }
    
    func register(username:String, password:String, callback:(success:Bool) -> Void) {
        return auth("register", username:username, password:password, callback:callback);
    }

    func login(username:String, password:String, callback:(success:Bool) -> Void) {

        return auth("login", username:username, password:password, callback:callback);
    
    }

    // wait for  push token, creds, and masterVC then reauth
    func reauth(callback:((success:Bool) -> Void)?=nil) {
        if callback != nil {
            self.reauthed = callback
        }
        if (self.reauthed == nil) || (self.pushToken == nil)  {
            return
        }
        guard let creds = Login.loadCredentials() else {
            print("missing creds in keychain")
            self.reauthed!(success:false)
            return
        }
        self.login(creds.username, password: creds.password, callback:self.reauthed!)
    }
    
    func auth(endpoint:String, username:String, password:String, callback:((success:Bool) -> Void)) {
        let credentials = ["username":username, "password":password, "pushToken":self.pushToken!]
        HttpHelper.post(credentials, url:serverAddress + endpoint, callback:{
            if $0 == 200 {
                
                Login.saveCredentials(username, password:password)

                let response = $1 as! [String:String];
                self.session = response["session"]!
                print("session = " + self.session!)
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
    
    func logout() {
        self.session = nil
        do {
            try Locksmith.deleteDataForUserAccount("ClearKeep")
        } catch let error as NSError {
            print("could not remove from keychain: " + String(error))
        }
    }
    
    func befriend(friend:String, callback:(success:Bool) -> Void) {
        HttpHelper.post([friend:friend], url:serverAddress+"befriend" /*+Rest.session!*/, callback:{
            $1 // noop
            callback(success:$0 == 200)
        })
    }
}