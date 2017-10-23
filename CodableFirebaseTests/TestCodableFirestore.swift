//
//  TestCodableFirestore.swift
//  SlapTests
//
//  Created by Oleksii on 20/10/2017.
//  Copyright © 2017 Slap. All rights reserved.
//

import XCTest
import CodableFirebase

fileprivate struct Document: Codable, Equatable {
    let stringExample: String
    let booleanExample: Bool
    let numberExample: Double
    let dateExample: Date
    let arrayExample: [String]
    let nullExample: Int?
    let objectExample: [String: String]
    
    static func == (lhs: Document, rhs: Document) -> Bool {
        return lhs.stringExample == rhs.stringExample
            && lhs.booleanExample == rhs.booleanExample
            && lhs.numberExample == rhs.numberExample
            && lhs.dateExample == rhs.dateExample
            && lhs.arrayExample == rhs.arrayExample
            && lhs.nullExample == rhs.nullExample
            && lhs.objectExample == rhs.objectExample
    }
}

fileprivate struct EmptyStruct : Codable, Equatable {
    static func ==(_ lhs: EmptyStruct, _ rhs: EmptyStruct) -> Bool {
        return true
    }
}

fileprivate class EmptyClass : Codable, Equatable {
    static func ==(_ lhs: EmptyClass, _ rhs: EmptyClass) -> Bool {
        return true
    }
}

// MARK: - Single-Value Types
/// A simple on-off switch type that encodes as a single Bool value.
fileprivate enum Switch : Codable {
    case off
    case on
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        switch try container.decode(Bool.self) {
        case false: self = .off
        case true:  self = .on
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .off: try container.encode(false)
        case .on:  try container.encode(true)
        }
    }
}

/// A simple timestamp type that encodes as a single Double value.
fileprivate struct Timestamp : Codable, Equatable {
    let value: Double
    
    init(_ value: Double) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(Double.self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.value)
    }
    
    static func ==(_ lhs: Timestamp, _ rhs: Timestamp) -> Bool {
        return lhs.value == rhs.value
    }
}

/// A simple referential counter type that encodes as a single Int value.
fileprivate final class Counter : Codable, Equatable {
    var count: Int = 0
    
    init() {}
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        count = try container.decode(Int.self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.count)
    }
    
    static func ==(_ lhs: Counter, _ rhs: Counter) -> Bool {
        return lhs === rhs || lhs.count == rhs.count
    }
}

// MARK: - Structured Types
/// A simple address type that encodes as a dictionary of values.
fileprivate struct Address : Codable, Equatable {
    let street: String
    let city: String
    let state: String
    let zipCode: Int
    let country: String
    
    init(street: String, city: String, state: String, zipCode: Int, country: String) {
        self.street = street
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
    }
    
    static func ==(_ lhs: Address, _ rhs: Address) -> Bool {
        return lhs.street == rhs.street &&
            lhs.city == rhs.city &&
            lhs.state == rhs.state &&
            lhs.zipCode == rhs.zipCode &&
            lhs.country == rhs.country
    }
    
    static var testValue: Address {
        return Address(street: "1 Infinite Loop",
                       city: "Cupertino",
                       state: "CA",
                       zipCode: 95014,
                       country: "United States")
    }
}

/// A simple person class that encodes as a dictionary of values.
fileprivate class Person : Codable, Equatable {
    let name: String
    let email: String
    let website: URL?
    
    init(name: String, email: String, website: URL? = nil) {
        self.name = name
        self.email = email
        self.website = website
    }
    
    private enum CodingKeys : String, CodingKey {
        case name
        case email
        case website
    }
    
    // FIXME: Remove when subclasses (Employee) are able to override synthesized conformance.
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        website = try container.decodeIfPresent(URL.self, forKey: .website)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        try container.encodeIfPresent(website, forKey: .website)
    }
    
    func isEqual(_ other: Person) -> Bool {
        return self.name == other.name &&
            self.email == other.email &&
            self.website == other.website
    }
    
    static func ==(_ lhs: Person, _ rhs: Person) -> Bool {
        return lhs.isEqual(rhs)
    }
    
    class var testValue: Person {
        return Person(name: "Johnny Appleseed", email: "appleseed@apple.com")
    }
}

/// A class which shares its encoder and decoder with its superclass.
fileprivate class Employee : Person {
    let id: Int
    
    init(name: String, email: String, website: URL? = nil, id: Int) {
        self.id = id
        super.init(name: name, email: email, website: website)
    }
    
    enum CodingKeys : String, CodingKey {
        case id
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try super.encode(to: encoder)
    }
    
    override func isEqual(_ other: Person) -> Bool {
        if let employee = other as? Employee {
            guard self.id == employee.id else { return false }
        }
        
        return super.isEqual(other)
    }
    
    override class var testValue: Employee {
        return Employee(name: "Johnny Appleseed", email: "appleseed@apple.com", id: 42)
    }
}

/// A simple company struct which encodes as a dictionary of nested values.
fileprivate struct Company : Codable, Equatable {
    let address: Address
    var employees: [Employee]
    
    init(address: Address, employees: [Employee]) {
        self.address = address
        self.employees = employees
    }
    
    static func ==(_ lhs: Company, _ rhs: Company) -> Bool {
        return lhs.address == rhs.address && lhs.employees == rhs.employees
    }
    
    static var testValue: Company {
        return Company(address: Address.testValue, employees: [Employee.testValue])
    }
}

/// An enum type which decodes from Bool?.
fileprivate enum EnhancedBool : Codable {
    case `true`
    case `false`
    case fileNotFound
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .fileNotFound
        } else {
            let value = try container.decode(Bool.self)
            self = value ? .true : .false
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .true: try container.encode(true)
        case .false: try container.encode(false)
        case .fileNotFound: try container.encodeNil()
        }
    }
}

/// A type which encodes as a dictionary directly through a single value container.
fileprivate final class Mapping : Codable, Equatable {
    let values: [String : URL]
    
    init(values: [String : URL]) {
        self.values = values
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        values = try container.decode([String : URL].self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }
    
    static func ==(_ lhs: Mapping, _ rhs: Mapping) -> Bool {
        return lhs === rhs || lhs.values == rhs.values
    }
    
    static var testValue: Mapping {
        return Mapping(values: ["Apple": URL(string: "http://apple.com")!,
                                "localhost": URL(string: "http://127.0.0.1")!])
    }
}

/// Wraps a type T so that it can be encoded at the top level of a payload.
fileprivate struct TopLevelWrapper<T> : Codable, Equatable where T : Codable, T : Equatable {
    let value: T
    
    init(_ value: T) {
        self.value = value
    }
    
    static func ==(_ lhs: TopLevelWrapper<T>, _ rhs: TopLevelWrapper<T>) -> Bool {
        return lhs.value == rhs.value
    }
}

class TestCodableFirestore: XCTestCase {
    
    func testFirebaseEncoder() {
        let model = Document(
            stringExample: "Hello world!",
            booleanExample: true,
            numberExample: 3.14159265,
            dateExample: Date(),
            arrayExample: ["hello", "world"],
            nullExample: nil,
            objectExample: ["objectExample": "one"]
        )
        
        let dict: [String : Any] = [
            "stringExample": "Hello world!",
            "booleanExample": true,
            "numberExample": 3.14159265,
            "dateExample": model.dateExample,
            "arrayExample": ["hello", "world"],
            "objectExample": ["objectExample": "one"]
        ]
        
        XCTAssertEqual((try FirestoreEncoder().encode(model)) as NSDictionary, dict as NSDictionary)
        XCTAssertEqual(try? FirestoreDecoder().decode(Document.self, from: dict) , model)
    }
    
    func testEncodingTopLevelEmptyStruct() {
        _testRoundTrip(of: EmptyStruct(), expected: [:])
    }
    
    func testEncodingTopLevelEmptyClass() {
        _testRoundTrip(of: EmptyClass(), expected: [:])
    }
    
    // MARK: - Encoding Top-Level Single-Value Types
    func testEncodingTopLevelSingleValueEnum() {
        let s1 = Switch.off
        _testEncodeFailure(of: s1)
        _testRoundTrip(of: TopLevelWrapper(s1))
        
        let s2 = Switch.on
        _testEncodeFailure(of: s2)
        _testRoundTrip(of: TopLevelWrapper(s2))
    }
    
    func testEncodingTopLevelSingleValueStruct() {
        let t = Timestamp(3141592653)
        _testEncodeFailure(of: t)
        _testRoundTrip(of: TopLevelWrapper(t))
    }
    
    func testEncodingTopLevelSingleValueClass() {
        let c = Counter()
        _testEncodeFailure(of: c)
        _testRoundTrip(of: TopLevelWrapper(c))
    }
    
    // MARK: - Encoding Top-Level Structured Types
    func testEncodingTopLevelStructuredStruct() {
        // Address is a struct type with multiple fields.
        _testRoundTrip(of: Address.testValue)
    }
    
    func testEncodingTopLevelStructuredClass() {
        // Person is a class with multiple fields.
        _testRoundTrip(of: Person.testValue)
    }
    
    func testEncodingTopLevelStructuredSingleClass() {
        // Mapping is a class which encodes as a dictionary through a single value container.
        _testRoundTrip(of: Mapping.testValue)
    }
    
    func testEncodingTopLevelDeepStructuredType() {
        // Company is a type with fields which are Codable themselves.
        _testRoundTrip(of: Company.testValue)
    }
    
    func testEncodingClassWhichSharesEncoderWithSuper() {
        // Employee is a type which shares its encoder & decoder with its superclass, Person.
        _testRoundTrip(of: Employee.testValue)
    }
    
    func testEncodingTopLevelNullableType() {
        // EnhancedBool is a type which encodes either as a Bool or as nil.
        _testEncodeFailure(of: EnhancedBool.true)
        _testEncodeFailure(of: EnhancedBool.false)
        _testEncodeFailure(of: EnhancedBool.fileNotFound)
        
        _testRoundTrip(of: TopLevelWrapper(EnhancedBool.true))
        _testRoundTrip(of: TopLevelWrapper(EnhancedBool.false))
        _testRoundTrip(of: TopLevelWrapper(EnhancedBool.fileNotFound))
    }
    
    func testTypeCoercion() {
        _testRoundTripTypeCoercionFailure(of: [false, true], as: [Int].self)
        _testRoundTripTypeCoercionFailure(of: [false, true], as: [Int8].self)
        _testRoundTripTypeCoercionFailure(of: [false, true], as: [Int16].self)
        _testRoundTripTypeCoercionFailure(of: [false, true], as: [Int32].self)
        _testRoundTripTypeCoercionFailure(of: [false, true], as: [Int64].self)
        _testRoundTripTypeCoercionFailure(of: [false, true], as: [UInt].self)
        _testRoundTripTypeCoercionFailure(of: [false, true], as: [UInt8].self)
        _testRoundTripTypeCoercionFailure(of: [false, true], as: [UInt16].self)
        _testRoundTripTypeCoercionFailure(of: [false, true], as: [UInt32].self)
        _testRoundTripTypeCoercionFailure(of: [false, true], as: [UInt64].self)
        _testRoundTripTypeCoercionFailure(of: [false, true], as: [Float].self)
        _testRoundTripTypeCoercionFailure(of: [false, true], as: [Double].self)
        _testRoundTripTypeCoercionFailure(of: [0, 1] as [Int], as: [Bool].self)
        _testRoundTripTypeCoercionFailure(of: [0, 1] as [Int8], as: [Bool].self)
        _testRoundTripTypeCoercionFailure(of: [0, 1] as [Int16], as: [Bool].self)
        _testRoundTripTypeCoercionFailure(of: [0, 1] as [Int32], as: [Bool].self)
        _testRoundTripTypeCoercionFailure(of: [0, 1] as [Int64], as: [Bool].self)
        _testRoundTripTypeCoercionFailure(of: [0, 1] as [UInt], as: [Bool].self)
        _testRoundTripTypeCoercionFailure(of: [0, 1] as [UInt8], as: [Bool].self)
        _testRoundTripTypeCoercionFailure(of: [0, 1] as [UInt16], as: [Bool].self)
        _testRoundTripTypeCoercionFailure(of: [0, 1] as [UInt32], as: [Bool].self)
        _testRoundTripTypeCoercionFailure(of: [0, 1] as [UInt64], as: [Bool].self)
        _testRoundTripTypeCoercionFailure(of: [0.0, 1.0] as [Float], as: [Bool].self)
        _testRoundTripTypeCoercionFailure(of: [0.0, 1.0] as [Double], as: [Bool].self)
    }
    
    private func _testEncodeFailure<T : Encodable>(of value: T) {
        do {
            let _ = try FirestoreEncoder().encode(value)
            XCTFail("Encode of top-level \(T.self) was expected to fail.")
        } catch {}
    }
    
    private func _testRoundTripTypeCoercionFailure<T,U>(of value: T, as type: U.Type) where T : Codable, U : Codable {
        do {
            let data = try FirestoreEncoder().encode(value)
            let _ = try FirestoreDecoder().decode(U.self, from: data)
            XCTFail("Coercion from \(T.self) to \(U.self) was expected to fail.")
        } catch {}
    }
    
    private func _testRoundTrip<T>(of value: T, expected dict: [String: Any]? = nil) where T : Codable, T : Equatable {
        var payload: [String: Any]! = nil
        do {
            payload = try FirestoreEncoder().encode(value)
        } catch {
            XCTFail("Failed to encode \(T.self) to plist: \(error)")
        }
        
        if let expectedDict = dict {
            XCTAssertEqual(payload as NSDictionary, expectedDict as NSDictionary, "Produced dictionary not identical to expected dictionary")
        }
        
        do {
            let decoded = try FirestoreDecoder().decode(T.self, from: payload)
            XCTAssertEqual(decoded, value, "\(T.self) did not round-trip to an equal value.")
        } catch {
            XCTFail("Failed to decode \(T.self) from plist: \(error)")
        }
    }
}
