import Foundation

class HttpHelper {

    typealias Callback = (status:Int, response:AnyObject?) -> Void;

    static func get(params : Dictionary<String, String>?, url : String, callback:Callback) {
        HttpHelper.request("GET", params: params, url: url, callback: callback);
    }

    static func post(params : Dictionary<String, String>?, url : String, callback:Callback) {
        HttpHelper.request("POST", params: params, url: url, callback: callback);
    }

    static func request(method:String, params : Dictionary<String, String>?, url : String, callback:Callback) {
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
        let task = session.dataTaskWithRequest(request, completionHandler: { data, response, error -> Void in

            // parse the response
            print("Response: \(response)")
//            if response != nil
            let statusCode = (response as! NSHTTPURLResponse).statusCode;
            if statusCode != 200 {
                callback(status:statusCode, response:nil);
            } else {
            
                let strData = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Body: \(strData)")

                // parse the response JSON
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSDictionary
                    if let parsedJSON = json {
                        
                        // callback
                        callback(status:statusCode, response:parsedJSON);
                    }
                } catch {
                    let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                    print("Error could not parse JSON: '\(jsonStr)'")
                }
            }
        })
        
        task!.resume()
    }

/*

func HTTPsendRequest(request: NSMutableURLRequest, callback: (String, String?) -> Void) {
        let task = NSURLSession.sharedSession().dataTaskWithRequest(
            request,
            completionHandler: {
                data, response, error in
                if error != nil {
                    callback("", error!.localizedDescription)
                } else {
                    callback(
                        NSString(data: data!, encoding: NSUTF8StringEncoding)! as String,
                        nil
                    )
                }
        })
        
        task!.resume()
}

func JSONStringify(value: AnyObject, prettyPrinted: Bool = false) -> String {
    if NSJSONSerialization.isValidJSONObject(value) {
        
        let data = try NSJSONSerialization.dataWithJSONObject(value, options: NSJSONWritingOptions.PrettyPrinted) {
            return NSString(data: data, encoding: NSUTF8StringEncoding) as! String
        } catch let serializationError as NSError {
            println(serializationError)
        }
    }
    return ""
}

func HTTPPostJSON(url: String, jsonObj: AnyObject, callback: (String, String?) -> Void) {
    let request = NSMutableURLRequest(URL: NSURL(string: url)!)
    request.HTTPMethod = "POST"
    request.addValue("application/json",
    forHTTPHeaderField: "Content-Type")
    let jsonString = JSONStringify(jsonObj)
    let data: NSData = jsonString.dataUsingEncoding(NSUTF8StringEncoding)!
    request.HTTPBody = data
    HTTPsendRequest(request, callback:callback)
}

*/

}