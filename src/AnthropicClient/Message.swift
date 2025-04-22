//
//  Message.swift
//  swift-ai-agent
//
//  Created by Tornike Gomareli on 23.04.25.
//

/// Message structure for Anthropic API
public struct Message: Codable {
  let role: Role
  let content: String
  
  public init(role: Role, content: String) {
    self.role = role
    self.content = content
  }
}
