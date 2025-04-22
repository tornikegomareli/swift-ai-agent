import Foundation

// Assuming ToolDefinition, SchemaProperty, ToolInputSchema structures exist as you defined them.

/// Example of creating a ReadFile tool for the Agent - Reads a specific relative path.
func createReadFileTool() -> ToolDefinition {
  let pathProperty = SchemaProperty(
    type: "string",
    // Clarify that the path is relative to the agent's runtime CWD
    description: "The relative path of the file to read, starting from the agent's current working directory."
  )
  
  let inputSchema = ToolInputSchema(
    type: "object",
    properties: ["path": pathProperty],
    required: ["path"]
  )
  
  return ToolDefinition(
    name: "read_file",
    // Clarify description
    description: "Read the contents of a file at a specified relative path from the current working directory.",
    inputSchema: inputSchema
  ) { input in
    guard let relativePath = input["path"] as? String else {
      throw NSError(
        domain: "ToolError",
        code: 400,
        userInfo: [NSLocalizedDescriptionKey: "Missing required parameter: path"]
      )
    }
    
    let fileManager = FileManager.default
    let currentWorkingDirectory = fileManager.currentDirectoryPath
    
    // --- IMPORTANT: Log the CWD for debugging ---
    // This will show you where the agent is *actually* running from when it uses the tool.
    fputs("DEBUG: [ReadFileTool] Agent CWD: \(currentWorkingDirectory)\n", stderr)
    fputs("DEBUG: [ReadFileTool] Requested relative path: \(relativePath)\n", stderr)
    // --- End Logging ---
    
    // Construct the full URL by resolving the relative path against the CWD
    // Using URLs is generally safer for path manipulation.
    let currentWorkingURL = URL(fileURLWithPath: currentWorkingDirectory, isDirectory: true)
    // Resolve the relative path against the CWD base URL
    let fileURL = URL(fileURLWithPath: relativePath, relativeTo: currentWorkingURL).standardizedFileURL
    
    fputs("DEBUG: [ReadFileTool] Attempting to read absolute path: \(fileURL.path)\n", stderr)
    
    // Check if the file exists at the specific constructed path
    guard fileManager.fileExists(atPath: fileURL.path) else {
      fputs("ERROR: [ReadFileTool] File does not exist at path: \(fileURL.path)\n", stderr)
      // Provide a more informative error message including the CWD and path tried
      throw NSError(
        domain: "ReadFileError",
        code: 404, // Not Found
        userInfo: [NSLocalizedDescriptionKey: "File not found at relative path '\(relativePath)' from CWD '\(currentWorkingDirectory)'. Full path checked: \(fileURL.path)"]
      )
    }
    
    // Check if it's actually a file and not a directory, as read content expects a file
    var isDirectory: ObjCBool = false
    if fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
      fputs("ERROR: [ReadFileTool] Path points to a directory, not a file: \(fileURL.path)\n", stderr)
      throw NSError(
        domain: "ReadFileError",
        code: 400, // Bad Request - input path type is wrong
        userInfo: [NSLocalizedDescriptionKey: "The specified path '\(relativePath)' points to a directory, not a file."]
      )
    }
    
    // Attempt to read the file content directly from the constructed URL
    do {
      let content = try String(contentsOf: fileURL, encoding: .utf8)
      fputs("SUCCESS: [ReadFileTool] Read content from \(fileURL.path)\n", stderr) // Debug log
      return content // Success! Return the content.
    } catch {
      // Handle errors during file reading (e.g., permissions, encoding issue)
      fputs("ERROR: [ReadFileTool] Failed to read content from \(fileURL.path): \(error.localizedDescription)\n", stderr)
      throw NSError(
        domain: "ReadFileError",
        code: 500, // Internal Server Error / Failed Operation
        userInfo: [NSLocalizedDescriptionKey: "Failed to read file content from '\(relativePath)': \(error.localizedDescription). Full path: \(fileURL.path)"]
      )
    }
  }
}
