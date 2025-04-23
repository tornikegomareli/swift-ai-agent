//
//  edit_file_tool.swift
//  swift-ai-agent
//
//  Created by Tornike Gomareli on 23.04.25.
//

import Foundation

/// Creates a ToolDefinition for editing/overwriting the content of a file.
func createEditFileTool() -> ToolDefinition {
  // `path`: The relative path of the file to edit (required).
  let pathProperty = SchemaProperty(
    type: "string",
    description:
      "The relative path of the file to be edited/overwritten, starting from the agent's current working directory."
  )

  // `content`: The new content to write into the file (required).
  let contentProperty = SchemaProperty(
    type: "string",
    description:
      "The new text content that will completely replace the existing content of the file."
  )

  let inputSchema = ToolInputSchema(
    type: "object",
    properties: [
      "path": pathProperty,
      "content": contentProperty,
    ],
    required: ["path", "content"]  // Both path and content are required
  )

  return ToolDefinition(
    name: "edit_file",
    description:
      "Overwrites the entire content of a specified file with new content. WARNING: This action is irreversible. Use with extreme caution.",
    inputSchema: inputSchema
  ) { input in  // This is the execution closure

    guard let relativePath = input["path"] as? String, !relativePath.isEmpty else {
      throw NSError(
        domain: "ToolError",
        code: 400,  // Bad Request
        userInfo: [NSLocalizedDescriptionKey: "Missing or empty required parameter: path"]
      )
    }

    // Content can technically be empty, so we just check for presence and type
    guard let newContent = input["content"] as? String else {
      throw NSError(
        domain: "ToolError",
        code: 400,  // Bad Request
        userInfo: [
          NSLocalizedDescriptionKey:
            "Missing or invalid type for required parameter: content (must be a string)"
        ]
      )
    }

    let fileManager = FileManager.default
    let currentWorkingDirectory = fileManager.currentDirectoryPath
    let currentWorkingURL = URL(fileURLWithPath: currentWorkingDirectory, isDirectory: true)

    let fileURL = URL(fileURLWithPath: relativePath, relativeTo: currentWorkingURL)
      .standardizedFileURL
    let filePath = fileURL.path

    fputs("DEBUG: [EditFileTool] Agent CWD: \(currentWorkingDirectory)\n", stderr)
    fputs("DEBUG: [EditFileTool] Requested relative path: \(relativePath)\n", stderr)
    fputs("DEBUG: [EditFileTool] Attempting to write to absolute path: \(filePath)\n", stderr)
    // Avoid logging full content unless absolutely necessary for debugging, it could be large or sensitive
    fputs("DEBUG: [EditFileTool] New content length: \(newContent.count) characters\n", stderr)

    guard fileManager.fileExists(atPath: filePath) else {
      fputs("ERROR: [EditFileTool] File to edit does not exist at path: \(filePath)\n", stderr)
      // Note: You *could* modify this tool to *create* the file if it doesn't exist,
      // but the current definition implies editing an *existing* file.
      throw NSError(
        domain: "EditFileError",
        code: 404,  // Not Found
        userInfo: [
          NSLocalizedDescriptionKey:
            "File not found at relative path '\(relativePath)'. Cannot edit a non-existent file. Full path checked: \(filePath)"
        ]
      )
    }

    // 2. Check if it's a file (not a directory)
    var isDirectory: ObjCBool = false
    // Re-check with isDirectory pointer
    if fileManager.fileExists(atPath: filePath, isDirectory: &isDirectory), isDirectory.boolValue {
      fputs("ERROR: [EditFileTool] Path points to a directory, not a file: \(filePath)\n", stderr)
      throw NSError(
        domain: "EditFileError",
        code: 400,  // Bad Request - trying to edit a directory
        userInfo: [
          NSLocalizedDescriptionKey:
            "The specified path '\(relativePath)' points to a directory, not a file. Cannot edit a directory."
        ]
      )
    }

    // --- Attempt to Write File Content ---
    do {
      // Write the new content, overwriting the existing file.
      // `atomically: true` writes to a temporary file first, then replaces the original,
      // which is safer in case of interruption.
      try newContent.write(to: fileURL, atomically: true, encoding: .utf8)

      fputs("SUCCESS: [EditFileTool] Successfully overwrote content of: \(filePath)\n", stderr)

      // Return a success message
      return "Successfully updated file: \(relativePath)" as String  // Cast if needed

    } catch {
      // Handle errors during file writing (e.g., permissions, disk full)
      fputs(
        "ERROR: [EditFileTool] Failed to write content to \(filePath): \(error.localizedDescription)\n",
        stderr)
      throw NSError(
        domain: "EditFileError",
        code: 500,  // Internal Server Error / Write Failed
        userInfo: [
          NSLocalizedDescriptionKey:
            "Failed to write content to file '\(relativePath)': \(error.localizedDescription). Full path: \(filePath)"
        ]
      )
    }
  }
}
