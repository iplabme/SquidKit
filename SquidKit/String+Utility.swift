//
//  String+Utility.swift
//  SquidKit
//
//  Created by Mike Leavy on 8/17/14.
//  Copyright © 2017-2019 Squid Store, LLC. All rights reserved.
//

import UIKit

public extension String {
    
    static func nonNilString(_ string:String?, stringForNil:String = "") -> String {
        if let nonNilString = string {
            return nonNilString
        }
        
        return stringForNil
    }

    static func guid() -> String {
        let uuid:CFUUID = CFUUIDCreate(kCFAllocatorDefault)

        let guid = CFUUIDCreateString(kCFAllocatorDefault, uuid) as NSString
        return guid as String
    }
    
    static func deserializeJSON(_ jsonObject:AnyObject, pretty:Bool) -> String? {
        
        var result:String?
        
        if JSONSerialization.isValidJSONObject(jsonObject) {
            let outputStream:OutputStream = OutputStream.toMemory()
            outputStream.open()
            var error:NSError?
            let bytesWritten:Int = JSONSerialization.writeJSONObject(jsonObject, to: outputStream, options: pretty ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization.WritingOptions(rawValue: 0), error: &error)
            outputStream.close()
            
            if bytesWritten > 0 {
                if let data:Data = outputStream.property(forKey: Stream.PropertyKey.dataWrittenToMemoryStreamKey) as? Data {
                    result = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String?
                }
            }
        }
        
        return result
    }

    func stringByTrimmingLeadingWhitespace() -> String {
        if let range = self.range(of: "^\\s*", options:.regularExpression) {
            let result = self.replacingCharacters(in: range, with: "")
            return result
        }
        return self
    }

    func stringByTrimmingTrailingWhitespace() -> String {
        if let range = self.range(of: "\\s*$", options:.regularExpression) {
            let result = self.replacingCharacters(in: range, with: "")
            return result
        }
        return self
    }

    func phoneDigitsString() -> String {
        let characterSet = CharacterSet(charactersIn: "()- ")
        let components = self.components(separatedBy: characterSet)
        return components.joined(separator: "")
    }

    func phoneURL() -> URL {
        return URL(string: "tel://\(self.phoneDigitsString())")!
    }

    func validEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return predicate.evaluate(with: self)
    }
    
    
}

