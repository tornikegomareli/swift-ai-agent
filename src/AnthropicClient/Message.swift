///
/// Message structure for Anthropic API
///
/// Represents a single message in a conversation with Claude.
/// Each message has a role (user or assistant) and content.
///
/// Created by Tornike Gomareli on 23.04.25.
///

/// Message structure for Anthropic API
public struct Message: Codable {
  /// The role of the message sender (user or assistant)
  let role: Role
  /// The text content of the message
  let content: String
  
  /// Initialize a new message
  /// - Parameters:
  ///   - role: The role of the message sender (user or assistant)
  ///   - content: The text content of the message
  public init(role: Role, content: String) {
    self.role = role
    self.content = content
  }
}
