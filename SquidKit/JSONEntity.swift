//
//  JSONEntity.swift
//  SquidKit
//
//  Created by Mike Leavy on 9/3/14.
//  Copyright © 2014-2019 Squid Store, LLC. All rights reserved.
//

import Foundation


open class JSONEntity: Sequence {
    
    enum JSONEntityError: Error {
        case invalidKey
        case invalidValue
        case invalidFormat
        case invalidJSON
    }
    
    fileprivate struct Entity {
        var key: String
        var value: AnyObject
        
        init(_ key: String, _ value: AnyObject) {
            self.key = key
            self.value = value
        }
    }
    
    fileprivate var entity: Entity
    
    fileprivate class NilValue {
    }
    
    open var count: Int {
        if let array = self.array() {
            return array.count
        }
        else if let dictionary = self.dictionary() {
            return dictionary.count
        }
        return 0
    }
    
    open var isValid: Bool {
        if let _ = self.entity.value as? NilValue {
            return false
        }
        return true
    }
    
    open var key: String {
        return self.entity.key
    }
    
    open var realValue: AnyObject? {
        if let _ = self.entity.value as? NilValue {
            return nil
        }
        return self.entity.value
    }
    
    public init () {
        self.entity = Entity("", NilValue())
    }
    
    public init(_ key: String, _ value: AnyObject) {
        self.entity = Entity(key, value)
    }
    
    public init(resourceFilename: String) {
        let jsonEntity = JSONEntity.entityFromResourceFile(resourceFilename)
        self.entity = jsonEntity.entity;
    }
    
    public init(jsonDictionary: NSDictionary) {
        self.entity = Entity("", jsonDictionary)
    }
    
    public init(jsonArray: NSArray) {
        self.entity = Entity("", jsonArray)
    }
    
    open func string() -> String? {
        return self.stringWithDefault(nil)
    }
    
    open func array() -> NSArray? {
        return self.arrayWithDefault(nil)
    }
    
    open func dictionary() -> NSDictionary? {
        return self.dictionaryWithDefault(nil)
    }
    
    open func int() -> Int? {
        return self.intWithDefault(nil)
    }
    
    open func double() -> Double? {
        return self.doubleWithDefault(nil)
    }
    
    open func bool() -> Bool? {
        return self.boolWithDefault(nil)
    }
    
    open func stringWithDefault(_ defaultValue: String?) -> String? {
        return EntityConverter<String>().get(entity.value, defaultValue)
    }
    
    open func arrayWithDefault(_ defaultValue: NSArray?) -> NSArray? {
        return EntityConverter<NSArray>().get(entity.value, defaultValue)
    }
    
    open func dictionaryWithDefault(_ defaultValue: NSDictionary?) -> NSDictionary? {
        return EntityConverter<NSDictionary>().get(entity.value, defaultValue)
    }
    
    open func intWithDefault(_ defaultValue: Int?) -> Int? {
        if let int = EntityConverter<Int>().get(entity.value, nil) {
            return int
        }
        else if let intString = EntityConverter<String>().get(entity.value, nil) {
            return (intString as NSString).integerValue
        }
        return defaultValue
    }
    
    open func doubleWithDefault(_ defaultValue: Double?) -> Double? {
        if let double = EntityConverter<Double>().get(entity.value, nil) {
            return double
        }
        else if let doubleString = EntityConverter<String>().get(entity.value, nil) {
            return (doubleString as NSString).doubleValue
        }
        return defaultValue
    }
    
    open func boolWithDefault(_ defaultValue: Bool?) -> Bool? {
        if let bool = EntityConverter<Bool>().get(entity.value, nil) {
            return bool
        }
        else if let boolString = EntityConverter<String>().get(entity.value, nil) {
            return (boolString as NSString).boolValue
        }
        return defaultValue
    }
    
    open subscript(key: String) -> JSONEntity {
        if let e: NSDictionary = entity.value as? NSDictionary {
            if let object: AnyObject = e.object(forKey: key) as AnyObject? {
                return JSONEntity(key, object)
            }
        }
        return JSONEntity(key, NilValue())
    }
    
    open subscript(index: Int) -> JSONEntity? {
        if let array: NSArray = entity.value as? NSArray {
            return JSONEntity(self.entity.key, array[index] as AnyObject)
        }
        return nil
    }
    
    public typealias GeneratorType = JSONEntityGenerator
    open func makeIterator() -> GeneratorType {
        let generator = JSONEntityGenerator(self)
        return generator
    }
    
}

public extension JSONEntity {
    
    class func entityFromResourceFile(_ fileName: String) -> JSONEntity {
        var result: JSONEntity?
        
        if let inputStream = InputStream(fileAtPath: String.stringWithPathToResourceFile(fileName)) {
            inputStream.open()
            do {
                let serialized = try JSONSerialization.jsonObject(with: inputStream, options: JSONSerialization.ReadingOptions(rawValue: 0))
                
                if let serializedASDictionary = serialized as? NSDictionary {
                    result = JSONEntity(jsonDictionary: serializedASDictionary)
                }
                else if let serializedAsArray = serialized as? NSArray {
                    result = JSONEntity(jsonArray: serializedAsArray)
                }
                else {
                    result = JSONEntity()
                }
            }
            catch {
                result = JSONEntity()
            }
            
            inputStream.close()
        }
        else {
            result = JSONEntity()
        }
        
        return result!
    }
}

public extension JSONEntity {
    
    // this can be useful when deserializing elements directly into something like
    // Realm, which dies if it encounters null values
    func entityWithoutNullValues() throws -> JSONEntity {
        if let array = self.array() {
            let mutableArray = NSMutableArray(array: array)
            return JSONEntity(jsonArray: mutableArray)
        }
        else if let dictionary = self.dictionary() {
            let mutableDictionary = NSMutableDictionary(dictionary: dictionary)
            return JSONEntity(jsonDictionary: mutableDictionary)
        }
        
        throw JSONEntityError.invalidJSON
    }
    
    func removeNull(_ dictionary: NSMutableDictionary) {
        for key in dictionary.allKeys {
            let key = key as! String
            if let _ = dictionary[key] as? NSNull {
                dictionary.removeObject(forKey: key)
            }
            else if let arrayElement = dictionary[key] as? NSArray {
                let mutableArray = NSMutableArray(array: arrayElement)
                dictionary.setObject(mutableArray, forKey: key as NSCopying)
                self.removeNull(mutableArray)
            }
            else if let dictionaryElement = dictionary[key] as? NSDictionary {
                let mutableDictionary = NSMutableDictionary(dictionary: dictionaryElement)
                dictionary.setObject(mutableDictionary, forKey: key as NSCopying)
                self.removeNull(mutableDictionary)
            }
        }
    }
    
    func removeNull(_ array: NSMutableArray) {
        for element in array {
            if let dictionary = element as? NSDictionary {
                let mutableDictionary = NSMutableDictionary(dictionary: dictionary)
                array.replaceObject(at: array.index(of: dictionary), with: mutableDictionary)
                self.removeNull(mutableDictionary)
            }
        }
    }
}

public extension JSONEntity {
    
    func convertIfDate(_ datekeys: [String], formatter: DateFormatter) throws -> JSONEntity {
        if datekeys.contains(self.entity.key) {
            guard let value = self.entity.value as? String else {throw JSONEntityError.invalidValue}
            guard let date = formatter.date(from: value) else {throw JSONEntityError.invalidFormat}
            
            return JSONEntity(self.entity.key, date as AnyObject)
        }
        return self
    }
}

public struct JSONEntityGenerator: IteratorProtocol {
    public typealias Element = JSONEntity
    
    let entity: JSONEntity
    var sequenceIndex = 0
    
    public init(_ entity: JSONEntity) {
        self.entity = entity
    }
    
    public mutating func next() -> Element? {
        if let array = self.entity.array() {
            if sequenceIndex < array.count {
                let result = JSONEntity(self.entity.entity.key, array[sequenceIndex] as AnyObject)
                sequenceIndex += 1
                return result
            }
            else {
                sequenceIndex = 0
            }
        }
        else if let dictionary = self.entity.dictionary() {
            if sequenceIndex < dictionary.count {
                let result = JSONEntity(dictionary.allKeys[sequenceIndex] as! String, dictionary.object(forKey: dictionary.allKeys[sequenceIndex])! as AnyObject)
                sequenceIndex += 1
                return result
            }
            else {
                sequenceIndex = 0
            }
        }
        return .none
    }
}



private class EntityConverter<T> {
    init() {
    }
    
    func get(_ entity: AnyObject, _ defaultValue: T? = nil) -> T? {
        if let someEntity: T = entity as? T {
            return someEntity
        }
        return defaultValue
    }
}
