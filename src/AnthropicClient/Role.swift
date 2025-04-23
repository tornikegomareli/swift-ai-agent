///
/// Message role for Anthropic API
///
/// Represents the role of a message sender in a conversation with Claude.
/// Messages can be sent by either the user or the assistant (Claude).
///
/// Created by Tornike Gomareli on 23.04.25.
///

/// Message role for Anthropic API
public enum Role: String, Codable {
  /// Represents a message sent by the user
  case user
  /// Represents a message sent by the assistant (Claude)
  case assistant
}
