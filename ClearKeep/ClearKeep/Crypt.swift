import Foundation

func generateAesKeyForPassword(password: String, salt: NSData, roundCount: Int?, error: NSErrorPointer) -> (key: NSData, actualRoundCount: UInt32)? {
    let nsDerivedKey = NSMutableData(length: kCCKeySizeAES256)
    var actualRoundCount: UInt32
    
    // Create Swift intermediates for clarity in function calls
    let algorithm: CCPBKDFAlgorithm        = CCPBKDFAlgorithm(kCCPBKDF2)
    let prf:       CCPseudoRandomAlgorithm = CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256)
    let saltBytes  = UnsafePointer<UInt8>(salt.bytes)
    let saltLength = size_t(salt.length)
    let nsPassword        = password as NSString
    let nsPasswordPointer = UnsafePointer<Int8>(nsPassword.cStringUsingEncoding(NSUTF8StringEncoding))
    let nsPasswordLength  = size_t(nsPassword.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
    let nsDerivedKeyPointer = UnsafeMutablePointer<UInt8>(nsDerivedKey!.mutableBytes)
    let nsDerivedKeyLength = size_t(nsDerivedKey!.length)
    let msec: UInt32 = 300
    
    if roundCount != nil {
        actualRoundCount = UInt32(roundCount!)
    }
    else {
        actualRoundCount = CCCalibratePBKDF(
            algorithm,
            nsPasswordLength,
            saltLength,
            prf,
            nsDerivedKeyLength,
            msec);
    }
    
    let result = CCKeyDerivationPBKDF(
        algorithm,
        nsPasswordPointer,   nsPasswordLength,
        saltBytes,           saltLength,
        prf,                 actualRoundCount,
        nsDerivedKeyPointer, nsDerivedKeyLength)
    
    if result != 0 {
        NSLog("CCKeyDerivationPBKDF failed with error: '\(result)'")
        return nil
    }
    
    return (nsDerivedKey!, actualRoundCount)
}

func salt(length:Int) -> NSData {
    let salt        = NSMutableData(length: Int(length))
    let saltPointer = UnsafeMutablePointer<UInt8>(salt!.mutableBytes)
    SecRandomCopyBytes(kSecRandomDefault, length, saltPointer);
    return salt!
}