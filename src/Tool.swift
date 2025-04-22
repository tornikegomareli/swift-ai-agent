import Foundation

struct ToolDefinition {
  let name: String
  let description: String
  let inputSchema: [String: Any]
  let function: (Data) throws -> String
}
