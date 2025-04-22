//
//  MessageRequest.swift
//  swift-ai-agent
//
//  Created by Tornike Gomareli on 23.04.25.
//

/// Request model for creating a message
public struct MessageRequest: Codable {
  let model: String
  let max_tokens: Int
  let messages: [Message]
  
  public init(model: String, maxTokens: Int, messages: [Message]) {
    self.model = model
    self.max_tokens = maxTokens
    self.messages = messages
  }
}
