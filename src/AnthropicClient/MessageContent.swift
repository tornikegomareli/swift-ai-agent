//
//  MessageContent.swift
//  swift-ai-agent
//
//  Created by Tornike Gomareli on 23.04.25.
//

import Foundation

/// Message content types
public struct MessageContent: Codable {
  public let text: String?
  public let type: ContentType
  public let toolCall: ToolCall?
  
  public let id: String?
  public let name: String?
  public let input: [String: String]?
  
  enum CodingKeys: String, CodingKey {
    case type, text
    case id, name, input
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    type = try container.decode(ContentType.self, forKey: .type)
    text = try? container.decodeIfPresent(String.self, forKey: .text)
    
    if type == .toolCall {
      let id = try container.decode(String.self, forKey: .id)
      let name = try container.decode(String.self, forKey: .name)
      let input = try container.decode([String: String].self, forKey: .input)
      self.id = id
      self.name = name
      self.input = input
      toolCall = ToolCall(id: id, name: name, input: input)
    } else {
      toolCall = nil
      id = nil
      name = nil
      input = nil
    }
  }
}
