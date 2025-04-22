//
//  MessageRequest.swift
//  swift-ai-agent
//
//  Created by Tornike Gomareli on 23.04.25.
//

/// Request model for creating a message
struct MessageRequest: Codable {
  let model: String
  let maxTokens: Int
  let messages: [Message]
  let tools: [Tool]?
  
  init(model: String, maxTokens: Int, messages: [Message], tools: [Tool]? = nil) {
    self.model = model
    self.maxTokens = maxTokens
    self.messages = messages
    self.tools = tools
  }
  
  enum CodingKeys: String, CodingKey {
    case model
    case maxTokens = "max_tokens"
    case messages
    case tools
  }
}

/// Add content type to support tool calls
public enum ContentType: String, Codable {
  case text
  case toolCall = "tool_use"
  case toolResult = "tool_result"
}
