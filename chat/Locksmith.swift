//
//  Locksmith.swift
//
//  Created by Matthew Palmer on 26/10/2014.
//  Copyright (c) 2014 Colour Coding. All rights reserved.
//

import CoreFoundation
import Security
import Foundation

public let LocksmithDefaultService = NSBundle.mainBundle().infoDictionary![String(kCFBundleIdentifierKey)] as? String ?? "com.locksmith.defaultService"

// MARK: Locksmith Error
public enum LocksmithError: String, ErrorType {
    case Allocate = "Failed to allocate memory."
    case AuthFailed = "Authorization/Authentication failed."
    case Decode = "Unable to decode the provided data."
    case Duplicate = "The item already exists."
    case InteractionNotAllowed = "Interaction with the Security Server is not allowed."
    case NoError = "No error."
    case NotAvailable = "No trust results are available."
    case NotFound = "The item cannot be found."
    case Param = "One or more parameters passed to the function were not valid."
    case RequestNotSet = "The request was not set"
    case TypeNotFound = "The type was not found"
    case UnableToClear = "Unable to clear the keychain"
    case Undefined = "An undefined error occurred"
    case Unimplemented = "Function or operation not implemented."
    
    init?(fromStatusCode code: Int) {
        switch code {
        case Int(errSecAllocate):
            self = Allocate
        case Int(errSecAuthFailed):
            self = AuthFailed
        case Int(errSecDecode):
            self = Decode
        case Int(errSecDuplicateItem):
            self = Duplicate
        case Int(errSecInteractionNotAllowed):
            self = InteractionNotAllowed
        case Int(errSecItemNotFound):
            self = NotFound
        case Int(errSecNotAvailable):
            self = NotAvailable
        case Int(errSecParam):
            self = Param
        case Int(errSecUnimplemented):
            self = Unimplemented
        default:
            return nil
        }
    }
}

// MARK: Locksmith
public class Locksmith: NSObject {
    // MARK: Perform request
    public class func performRequest(request: LocksmithRequest) throws -> NSDictionary? {
        let type = request.type
        var result: AnyObject?
        var status: OSStatus?
        
        let parsedRequest: NSMutableDictionary = parseRequest(request)
        
        let requestReference = parsedRequest as CFDictionaryRef
        
        switch type {
        case .Create:
            status = withUnsafeMutablePointer(&result) { SecItemAdd(requestReference, UnsafeMutablePointer($0)) }
        case .Read:
            status = withUnsafeMutablePointer(&result) { SecItemCopyMatching(requestReference, UnsafeMutablePointer($0)) }
        case .Delete:
            status = SecItemDelete(requestReference)
        case .Update:
            status =  Locksmith.performUpdate(requestReference, result: &result)
        }
        
        guard let unwrappedStatus = status else {
            throw LocksmithError.TypeNotFound
        }
        
        let statusCode = Int(unwrappedStatus)
        if let error = LocksmithError(fromStatusCode: statusCode) {
            throw error
        }
        
        var resultsDictionary: NSDictionary?
        
        if result != nil && type == .Read && status == errSecSuccess {
            if let data = result as? NSData {
                // Convert the retrieved data to a dictionary
                resultsDictionary = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSDictionary
            }
        }
        
        return resultsDictionary
    }
    
    // MARK: Private methods
    private class func performUpdate(request: CFDictionaryRef, inout result: AnyObject?) -> OSStatus {
        // We perform updates to the keychain by first deleting the matching object, then writing to it with the new value.
        SecItemDelete(request)
        
        // Even if the delete request failed (e.g. if the item didn't exist before), still try to save the new item.
        // If we get an error saving, we'll tell the user about it.
        let status: OSStatus = withUnsafeMutablePointer(&result) { SecItemAdd(request, UnsafeMutablePointer($0)) }
        return status
    }
    
    private class func parseRequest(request: LocksmithRequest) -> NSMutableDictionary {
        var parsedRequest = NSMutableDictionary()
        
        var options = [String: AnyObject?]()
        options[String(kSecAttrAccount)] = request.userAccount
        options[String(kSecAttrAccessGroup)] = request.group
        options[String(kSecAttrService)] = request.service
        options[String(kSecAttrSynchronizable)] = request.synchronizable
        options[String(kSecClass)] = request.securityClass.rawValue
        
        if let accessibleMode = request.accessible {
            options[String(kSecAttrAccessible)] = accessibleMode.rawValue
        }
        
        for (key, option) in options {
            parsedRequest.setOptional(option, forKey: key)
        }
        
        switch request.type {
        case .Create:
            parsedRequest = parseCreateRequest(request, inDictionary: parsedRequest)
        case .Delete:
            parsedRequest = parseDeleteRequest(request, inDictionary: parsedRequest)
        case .Update:
            parsedRequest = parseCreateRequest(request, inDictionary: parsedRequest)
        default: // case .Read:
            parsedRequest = parseReadRequest(request, inDictionary: parsedRequest)
        }
        
        return parsedRequest
    }
    
    private class func parseCreateRequest(request: LocksmithRequest, inDictionary dictionary: NSMutableDictionary) -> NSMutableDictionary {
        
        if let data = request.data {
            let encodedData = NSKeyedArchiver.archivedDataWithRootObject(data)
            dictionary.setObject(encodedData, forKey: String(kSecValueData))
        }
        
        return dictionary
    }
    
    
    private class func parseReadRequest(request: LocksmithRequest, inDictionary dictionary: NSMutableDictionary) -> NSMutableDictionary {
        dictionary.setOptional(kCFBooleanTrue, forKey: String(kSecReturnData))
        
        switch request.matchLimit {
        case .One:
            dictionary.setObject(kSecMatchLimitOne, forKey: String(kSecMatchLimit))
        case .Many:
            dictionary.setObject(kSecMatchLimitAll, forKey: String(kSecMatchLimit))
        }
        
        return dictionary
    }
    
    private class func parseDeleteRequest(request: LocksmithRequest, inDictionary dictionary: NSMutableDictionary) -> NSMutableDictionary {
        return dictionary
    }
}

// MARK: Convenient Class Methods
extension Locksmith {
    public class func saveData(data: Dictionary<String, String>, forUserAccount userAccount: String, inService service: String = LocksmithDefaultService) throws {
        let saveRequest = LocksmithRequest(userAccount: userAccount, requestType: .Create, data: data, service: service)
        try Locksmith.performRequest(saveRequest)
    }
    
    public class func loadDataForUserAccount(userAccount: String, inService service: String = LocksmithDefaultService) -> NSDictionary? {
        let readRequest = LocksmithRequest(userAccount: userAccount, service: service)
        
        do {
            let dictionary = try Locksmith.performRequest(readRequest)
            return dictionary
        } catch {
            return nil
        }
    }
    
    public class func deleteDataForUserAccount(userAccount: String, inService service: String = LocksmithDefaultService) throws {
        let deleteRequest = LocksmithRequest(userAccount: userAccount, requestType: .Delete, service: service)
        try Locksmith.performRequest(deleteRequest)
    }
    
    public class func updateData(data: Dictionary<String, String>, forUserAccount userAccount: String, inService service: String = LocksmithDefaultService) throws {
        let updateRequest = LocksmithRequest(userAccount: userAccount, requestType: .Update, data: data, service: service)
        try Locksmith.performRequest(updateRequest)
    }
    
    public class func clearKeychain() throws {
        // Delete all of the keychain data of the given class
        func deleteDataForSecClass(secClass: CFTypeRef) throws {
            let request = NSMutableDictionary()
            request.setObject(secClass, forKey: String(kSecClass))
            
            let status: OSStatus? = SecItemDelete(request as CFDictionaryRef)
            
            if let status = status {
                let statusCode = Int(status)
                if let error = LocksmithError(fromStatusCode: statusCode) {
                    throw error
                }
            }
        }
        
        // For each of the sec class types, delete all of the saved items of that type
        let classes = [kSecClassGenericPassword, kSecClassInternetPassword, kSecClassCertificate, kSecClassKey, kSecClassIdentity]
        
        for classType in classes {
            do {
                try deleteDataForSecClass(classType)
            } catch let error as LocksmithError {
                // There was an error
                // If the error indicates that there was no item with that security class, that's fine.
                // Some of the sec classes will have nothing in them in most cases.
                if error != LocksmithError.NotFound {
                    throw LocksmithError.UnableToClear
                }
            }
        }
    }
}

// MARK: Dictionary Extension
extension NSMutableDictionary {
    func setOptional(optional: AnyObject?, forKey key: NSCopying) {
        if let object: AnyObject = optional {
            self.setObject(object, forKey: key)
        }
    }
}




//
//  LocksmithRequest.swift
//
//  Created by Matthew Palmer on 26/10/2014.
//  Copyright (c) 2014 Colour Coding. All rights reserved.
//

import Foundation
import Security

// With thanks to http://iosdeveloperzone.com/2014/10/22/taming-foundation-constants-into-swift-enums/

// MARK: Security Class
public enum SecurityClass: RawRepresentable {
    case GenericPassword, InternetPassword, Certificate, Key, Identity
    
    public init?(rawValue: String) {
        switch rawValue {
        case String(kSecClassGenericPassword):
            self = GenericPassword
        case String(kSecClassInternetPassword):
            self = InternetPassword
        case String(kSecClassCertificate):
            self = Certificate
        case String(kSecClassKey):
            self = Key
        case String(kSecClassIdentity):
            self = Identity
        default:
            print("SecurityClass: Invalid raw value provided. Defaulting to .GenericPassword")
            self = GenericPassword
        }
    }
    
    public var rawValue: String {
        switch self {
        case .GenericPassword:
            return String(kSecClassGenericPassword)
        case .InternetPassword:
            return String(kSecClassInternetPassword)
        case .Certificate:
            return String(kSecClassCertificate)
        case .Key:
            return String(kSecClassKey)
        case .Identity:
            return String(kSecClassIdentity)
        }
    }
}

// MARK: Accessible
public enum Accessible: RawRepresentable {
    case WhenUnlocked, AfterFirstUnlock, Always, WhenPasscodeSetThisDeviceOnly, WhenUnlockedThisDeviceOnly, AfterFirstUnlockThisDeviceOnly, AlwaysThisDeviceOnly
    
    public init?(rawValue: String) {
        switch rawValue {
        case String(kSecAttrAccessibleWhenUnlocked):
            self = WhenUnlocked
        case String(kSecAttrAccessibleAfterFirstUnlock):
            self = AfterFirstUnlock
        case String(kSecAttrAccessibleAlways):
            self = Always
        case String(kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly):
            self = WhenPasscodeSetThisDeviceOnly
        case String(kSecAttrAccessibleWhenUnlockedThisDeviceOnly):
            self = WhenUnlockedThisDeviceOnly
        case String(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly):
            self = AfterFirstUnlockThisDeviceOnly
        case String(kSecAttrAccessibleAlwaysThisDeviceOnly):
            self = AlwaysThisDeviceOnly
        default:
            print("Accessible: invalid rawValue provided. Defaulting to Accessible.WhenUnlocked.")
            self = WhenUnlocked
        }
    }
    
    public var rawValue: String {
        switch self {
        case .WhenUnlocked:
            return String(kSecAttrAccessibleWhenUnlocked)
        case .AfterFirstUnlock:
            return String(kSecAttrAccessibleAfterFirstUnlock)
        case .Always:
            return String(kSecAttrAccessibleAlways)
        case .WhenPasscodeSetThisDeviceOnly:
            return String(kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly)
        case .WhenUnlockedThisDeviceOnly:
            return String(kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
        case .AfterFirstUnlockThisDeviceOnly:
            return String(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)
        case .AlwaysThisDeviceOnly:
            return String(kSecAttrAccessibleAlwaysThisDeviceOnly)
        }
    }
}

// MARK: Match Limit
public enum MatchLimit {
    case One, Many
}

// MARK: Request Type
public enum RequestType {
    case Create, Read, Update, Delete
}

// MARK: Locksmith Request
public class LocksmithRequest: NSObject, CustomDebugStringConvertible {
    // Keychain Options
    // Required
    public var service: String = LocksmithDefaultService
    public var userAccount: String
    public var type: RequestType = .Read  // Default to non-destructive
    
    // Optional
    public var securityClass: SecurityClass = .GenericPassword  // Default to password lookup
    public var group: String?
    public var data: NSDictionary?
    public var matchLimit: MatchLimit = .One
    public var synchronizable = false
    public var accessible: Accessible?
    
    // Debugging
    override public var debugDescription: String {
        return "service: \(self.service), type: \(self.type), userAccount: \(self.userAccount)"
    }
    
    required public init(userAccount: String, service: String = LocksmithDefaultService) {
        self.service = service
        self.userAccount = userAccount
    }
    
    public convenience init(userAccount: String, requestType: RequestType, service: String = LocksmithDefaultService) {
        self.init(userAccount: userAccount, service: service)
        self.type = requestType
    }
    
    public convenience init(userAccount: String, requestType: RequestType, data: NSDictionary, service: String = LocksmithDefaultService) {
        self.init(userAccount: userAccount, requestType: requestType, service: service)
        self.data = data
    }
}