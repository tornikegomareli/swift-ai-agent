//
//  MessageResponse.swift
//  swift-ai-agent
//
//  Created by Tornike Gomareli on 23.04.25.
//

/// Response from message creation
public struct MessageResponse: Codable {
  let id: String
  let type: String
  let role: String
  let content: [MessageContent]
  let model: String
  let stopReason: String?
  let usage: Usage
  
  enum CodingKeys: String, CodingKey {
    case id, type, role, content, model
    case stopReason = "stop_reason"
    case usage
  }
  
  var hasToolCalls: Bool {
    return content.contains { $0.type == .toolCall && $0.toolCall != nil }
  }
  
  var toolCalls: [ToolCall] {
    return content.compactMap { $0.type == .toolCall ? $0.toolCall : nil }
  }
}
