//
//  Endpoint.swift
//  SquidKit
//
//  Created by Mike Leavy on 8/24/14.
//  Copyright © 2017-2019 Squid Store, LLC. All rights reserved.
//

import Foundation

// MARK: - Logging
public enum EndpointLogging {
    case none
    case minimal
    case verbose
}

public protocol EndpointLoggable {
    func log<T>(_ output:@autoclosure () -> T?)
    var requestLogging:EndpointLogging {get}
    var responseLogging:EndpointLogging {get}
}

open class Endpoint {
    
    public enum ResponseStatus {
        case ok
        case httpError(Int, String?)
        case notConnectedError
        case hostConnectionError
        case resourceUnavailableError
        case responseFormatError
        case unknownError(NSError?)
    }
    
    
    
    
// MARK: - Methods
    
    public init() {
        
    }
    
    // Return protocol - typically http or https, with or without "://"
    open func hostProtocol() -> String {
        return "http://"
    }
    
    // OVERRIDE: return host, e.g. "www.somehost.com"
    open func host() -> String {
        return ""
    }
    
    // OVERRIDE: return path, e.g. "resource/search"
    open func path() -> String {
        return ""
    }
    
    
    // OVERRIDE: return additional HTTP headers
    open func additionalHeaders() -> [NSObject : AnyObject]? {
        return nil
    }
    
    // OVERRIDE: return basic auth username / password
    open func basicAuthPair() -> (name:String?, password:String?) {
        return (nil, nil)
    }
    
    
    open func url() -> String {
        var aProtocol = self.hostProtocol()
        var aHost = self.host()
        
        if let mappedPair = EndpointMapper.mappedPairForCanonicalHost(aHost) {
            if mappedPair.hostProtocol != nil {
                aProtocol = mappedPair.hostProtocol!
            }
            if mappedPair.host != nil {
                aHost = mappedPair.host!
            }
        }
        
        var url = aProtocol
        
        if !url.hasSuffix("://") {
            url += "://"
        }
        
        url = url + aHost + "/" + self.path()
        return url
    }
    
    func formatError(_ response:HTTPURLResponse?, error:NSError?) -> ResponseStatus {
        if (response != nil) {
            var errorMessage:String?
            if let message = response!.allHeaderFields["Error"] as? String  {
                errorMessage = message
            }
            else if let message = response!.allHeaderFields["Status"] as? String {
                errorMessage = message
            }
            let statusCode = response!.statusCode
            
            return .httpError(statusCode, errorMessage)
        }
        else if (error != nil) {
            var responseStatus:ResponseStatus = .unknownError(error)
            switch error!.code {
            case NSURLErrorNotConnectedToInternet:
                responseStatus = .notConnectedError
            case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                responseStatus = .hostConnectionError
            case NSURLErrorResourceUnavailable:
                responseStatus = .resourceUnavailableError
            default:
                break
            }
            
            return responseStatus
        }
        
        return .unknownError(error)
    }
    
}

