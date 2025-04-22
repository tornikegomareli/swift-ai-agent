//
//  Tool.swift
//  swift-ai-agent
//
//  Created by Tornike Gomareli on 23.04.25.
//

import Foundation

public struct Tool: Codable {
  /// The name of the tool
  public let name: String
  
  /// Optional description of what the tool does
  public let description: String?
  
  /// JSON Schema defining the input parameters for the tool
  public let inputSchema: ToolInputSchema
  
  /// Create a new tool definition
  /// - Parameters:
  ///   - name: The name of the tool
  ///   - description: Optional description of the tool
  ///   - inputSchema: JSON Schema defining the input parameters
  public init(name: String, description: String? = nil, inputSchema: ToolInputSchema) {
    self.name = name
    self.description = description
    self.inputSchema = inputSchema
  }
  
  private enum CodingKeys: String, CodingKey {
    case name
    case description
    case inputSchema = "input_schema"
  }
}

/// JSON Schema for tool input
public struct ToolInputSchema: Codable {
  /// The type of the schema (usually "object")
  public let type: String
  
  /// Properties of the schema
  public let properties: [String: SchemaProperty]
  
  /// Required properties
  public let required: [String]?
  
  /// Create a new tool input schema
  /// - Parameters:
  ///   - type: The type of the schema (usually "object")
  ///   - properties: Properties of the schema
  ///   - required: Required properties
  public init(type: String = "object", properties: [String: SchemaProperty], required: [String]? = nil) {
    self.type = type
    self.properties = properties
    self.required = required
  }
}

/// Property in a JSON Schema
public struct SchemaProperty: Codable {
  /// The type of the property
  public let type: String
  
  /// Description of the property
  public let description: String?
  
  /// Create a new schema property
  /// - Parameters:
  ///   - type: The type of the property (string, number, boolean, etc.)
  ///   - description: Description of the property
  public init(type: String, description: String? = nil) {
    self.type = type
    self.description = description
  }
}

/// Tool call from Claude
public struct ToolCall: Codable {
  public let id: String
  public let name: String
  public let input: [String: Any]
  
  public init(id: String, name: String, input: [String: Any]) {
    self.id = id
    self.name = name
    self.input = input
  }
  
  enum CodingKeys: String, CodingKey {
    case id
    case name
    case input
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    name = try container.decode(String.self, forKey: .name)
    
    if let inputData = try? container.decode(Data.self, forKey: .input) {
      if let json = try? JSONSerialization.jsonObject(with: inputData) as? [String: Any] {
        input = json
      } else {
        input = [:]
      }
    } else if let inputDict = try? container.decode([String: AnyCodable].self, forKey: .input) {
      input = inputDict.mapValues { $0.value }
    } else {
      input = [:]
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(name, forKey: .name)
    
    // Encode input dictionary
    let inputDict = input.mapValues { AnyCodable($0) }
    try container.encode(inputDict, forKey: .input)
  }
}

/// Tool response to send back to Claude
public struct ToolResponse: Codable {
  /// The ID of the tool call this is responding to
  public let toolCallId: String
  
  /// The response content
  public let content: String
  
  /// Create a new tool response
  /// - Parameters:
  ///   - toolCallId: The ID of the tool call this is responding to
  ///   - content: The response content
  public init(toolCallId: String, content: String) {
    self.toolCallId = toolCallId
    self.content = content
  }
  
  private enum CodingKeys: String, CodingKey {
    case toolCallId = "tool_call_id"
    case content
  }
}

/// Helper for encoding/decoding Any values
public struct AnyCodable: Codable {
  public let value: Any
  
  public init(_ value: Any) {
    self.value = value
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    
    if container.decodeNil() {
      self.value = NSNull()
    } else if let bool = try? container.decode(Bool.self) {
      self.value = bool
    } else if let int = try? container.decode(Int.self) {
      self.value = int
    } else if let double = try? container.decode(Double.self) {
      self.value = double
    } else if let string = try? container.decode(String.self) {
      self.value = string
    } else if let array = try? container.decode([AnyCodable].self) {
      self.value = array.map { $0.value }
    } else if let dictionary = try? container.decode([String: AnyCodable].self) {
      self.value = dictionary.mapValues { $0.value }
    } else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode AnyCodable")
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    
    switch self.value {
    case is NSNull:
      try container.encodeNil()
    case let bool as Bool:
      try container.encode(bool)
    case let int as Int:
      try container.encode(int)
    case let double as Double:
      try container.encode(double)
    case let string as String:
      try container.encode(string)
    case let array as [Any]:
      try container.encode(array.map { AnyCodable($0) })
    case let dictionary as [String: Any]:
      try container.encode(dictionary.mapValues { AnyCodable($0) })
    default:
      throw EncodingError.invalidValue(self.value, EncodingError.Context(
        codingPath: container.codingPath,
        debugDescription: "Value cannot be encoded: \(type(of: self.value))"
      ))
    }
  }
}
