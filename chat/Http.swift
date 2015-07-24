import Foundation

class HttpHelper {
    
    typealias Callback = (status:Int, response:AnyObject?) -> Void;
    
    static func showProgress() {
        let deleage : UIApplicationDelegate = UIApplication.sharedApplication().delegate!;
        let loadingNotification = MBProgressHUD.showHUDAddedTo(deleage.window!, animated: true)
        loadingNotification.mode = MBProgressHUDMode.Indeterminate;
        loadingNotification.labelText = "Loading..."
    }
    
    static func dismissProgress() {
        dispatch_async(dispatch_get_main_queue(),{
            let deleage : UIApplicationDelegate = UIApplication.sharedApplication().delegate!;
            MBProgressHUD.hideAllHUDsForView(deleage.window!, animated: true);
        })
    }
    
    
    static func get(params : Dictionary<String, String>?, url : String, callback:Callback) {
        HttpHelper.request("GET", params: params, url: url, callback: callback);
    }
    
    static func post(params : Dictionary<String, String>?, url : String, callback:Callback) {
        HttpHelper.request("POST", params:params, url:url, callback:callback);
    }
    
    static func request(method:String, params : Dictionary<String, String>?, url : String, callback:Callback) {
        
        print(method + " " + url);
        
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = method
        
        // build the request
        if params != nil {
            do {
                try request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params!, options: NSJSONWritingOptions.PrettyPrinted)
            } catch {
                print("Error: could not construct JSON")
            }
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // make the request
        let task = session.dataTaskWithRequest(request, completionHandler: { data0, response, error -> Void in
            
            if error != nil {
                if error!.domain == NSURLErrorDomain && error!.code == NSURLErrorTimedOut {
                    print("timed out") // note, `response` is likely `nil` if it timed out
                } else {
                    print("HTTP error : " + error!.description)
                }
                
                //close progress popup
                dismissProgress();
            }
            
            if response != nil {
                
                // parse the response
                let statusCode = (response as! NSHTTPURLResponse).statusCode;
                if statusCode != 200 || data0 == nil {
                    callback(status:statusCode, response:nil);
                } else {
                    
                    let str = NSString(data: data0!, encoding: NSUTF8StringEncoding)!
                    let data = str.dataUsingEncoding(NSUTF8StringEncoding);
                    
                    // parse the response JSON
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves)
                        // callback
                        callback(status:statusCode, response:json);
                    } catch {
                        let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)!
                        print("Error could not parse JSON: '\(jsonStr)'")
                    }
                }
            }
        })
        
        task!.resume()
    }
}