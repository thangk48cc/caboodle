import Foundation

protocol RestDelegete {
    func registerFriendFall();
}

class Rest {

    enum Status { case Ok, NotFound }
    
    let serverAddress = "http://208.52.170.163:3000/"
    //let serverAddress = "http://127.0.0.1:3000/"
    //let serverAddress = "http://45.55.12.220:3000/"

    var delegate:RestDelegete! = nil
    var pushToken: String?
    
    func setPushToken(token:NSData) {
        self.pushToken = token.hexadecimalString
    }

    static let sharedInstance = Rest()

    func register(username:String, password:String, callback:(success:Bool, friends:[String]?) -> Void) {
        return auth("register", username:username, password:password, callback:callback);
    }

    func login(username:String, password:String, callback:(success:Bool, friends:[String]?) -> Void) {
        return auth("login", username:username, password:password, callback:callback);
    }

    func auth(endpoint:String, username:String, password:String, callback:((success:Bool, friends:[String]?) -> Void)) {
        
        let credentials = ["username":username, "password":password, "pushToken":self.pushToken!, "platform":platform]
        
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

    func logout() {
        HttpHelper.get(nil, url:serverAddress+"logout", callback:{
            $0;
            $1;
        });
    }

    func befriend(friend:String, foreva:Bool, tableView:ParentTableView) {
        let action = (foreva ? "add" : "del")
        HttpHelper.post(["username":friend, "action":action], url:serverAddress+"befriend", callback:{
            $1; // noop
            if $0 == 200 {
                //Login.config(ParentTableView, tableView:ParentTableView);
                Login.sharedInstance.reauth()
                dispatch_async(dispatch_get_main_queue(), {
                    tableView.reloadData()
                })
                
            } else {
                dispatch_async(dispatch_get_main_queue(), {
                    self.delegate.registerFriendFall();
                })
            }
            
            HttpHelper.dismissProgress();
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
        HttpHelper.post(["key":key, "value":value], url:serverAddress+"store", callback:{
            $1; // noop
            callback?(success:$0==204)
        })
    }

    func load(key:String, callback:(value:String?) -> Void) {
        HttpHelper.post(["key":key], url:serverAddress+"load", callback:{
            if $0 == 200 {
                let response = $1 as! [String:String]
                callback(value: response["value"])
            } else {
                callback(value: nil)
            }
        });
    }

    func call(receiver:String, callback:(success:Bool, port:Int) -> Void) {
        HttpHelper.post(["receiver":receiver], url:serverAddress+"call", callback:{
            if $0 == 200 {
                let response = $1 as! [String:Int]
                callback(success:true, port:response["port"]!)
            } else {
                callback(success:false, port:0)
            }
        });
    }
}

#if os(iOS)
var platform = "ios"
#endif
#if os(OSX)
    var platform = "osx"
#endif

