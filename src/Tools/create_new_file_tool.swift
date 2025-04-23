//
//  create_file_tool.swift
//  swift-ai-agent
//  Created by Tornike Gomareli on 23.04.25.
//

import Foundation

/// Creates a ToolDefinition for creating a new file with optional initial content.
///
/// This tool creates a new file at the specified path. It will fail if a file
/// or directory already exists at that path.
func createCreateFileTool() -> ToolDefinition {
  // `path`: The relative path where the new file should be created (required).
  let pathProperty = SchemaProperty(
    type: "string",
    description:
      "The relative path (including filename) where the new file should be created, starting from the agent's current working directory."
  )

  // `content`: Optional initial content for the new file.
  let contentProperty = SchemaProperty(
    type: "string",
    description:
      "Optional. The initial text content to write into the newly created file. Defaults to an empty file if omitted."
  )

  // --- Define the Input Schema ---
  let inputSchema = ToolInputSchema(
    type: "object",
    properties: [
      "path": pathProperty,
      "content": contentProperty,
    ],
    required: ["path"]
  )

  return ToolDefinition(
    name: "create_file",
    description:
      "Creates a new file at the specified relative path with optional initial content. Fails if a file or directory already exists at the path.",
    inputSchema: inputSchema
  ) { input in
    guard let relativePath = input["path"] as? String, !relativePath.isEmpty else {
      throw NSError(
        domain: "ToolError",
        code: 400,  // Bad Request
        userInfo: [NSLocalizedDescriptionKey: "Missing or empty required parameter: path"]
      )
    }
    // Content is optional, default to empty string if not provided or not a string
    let initialContent = input["content"] as? String ?? ""

    let fileManager = FileManager.default
    let currentWorkingDirectory = fileManager.currentDirectoryPath
    let currentWorkingURL = URL(fileURLWithPath: currentWorkingDirectory, isDirectory: true)

    // --- Determine Absolute File Path ---
    let fileURL = URL(fileURLWithPath: relativePath, relativeTo: currentWorkingURL)
      .standardizedFileURL
    let filePath = fileURL.path

    // Log details for debugging
    fputs("DEBUG: [CreateFileTool] Agent CWD: \(currentWorkingDirectory)\n", stderr)
    fputs("DEBUG: [CreateFileTool] Requested relative path: \(relativePath)\n", stderr)
    fputs(
      "DEBUG: [CreateFileTool] Attempting to create file at absolute path: \(filePath)\n", stderr)
    fputs(
      "DEBUG: [CreateFileTool] Initial content length: \(initialContent.count) characters\n", stderr
    )

    // --- Validate Target Path ---
    // 1. Check if anything already exists at the path
    if fileManager.fileExists(atPath: filePath) {
      fputs(
        "ERROR: [CreateFileTool] File or directory already exists at path: \(filePath)\n", stderr)
      throw NSError(
        domain: "CreateFileError",
        code: 409,  // Conflict - Resource already exists
        userInfo: [
          NSLocalizedDescriptionKey:
            "Cannot create file: A file or directory already exists at the specified path '\(relativePath)'. Full path checked: \(filePath)"
        ]
      )
    }

    // 2. Check if the parent directory exists. FileManager.createFile requires it.
    let parentDirectoryURL = fileURL.deletingLastPathComponent()
    var isParentDirectory: ObjCBool = false
    if !fileManager.fileExists(atPath: parentDirectoryURL.path, isDirectory: &isParentDirectory)
      || !isParentDirectory.boolValue
    {
      fputs(
        "ERROR: [CreateFileTool] Parent directory does not exist: \(parentDirectoryURL.path)\n",
        stderr)
      throw NSError(
        domain: "CreateFileError",
        code: 400,  // Bad Request (or 404 if preferred) - Prerequisite missing
        userInfo: [
          NSLocalizedDescriptionKey:
            "Cannot create file: The parent directory for path '\(relativePath)' does not exist. Full path checked: \(parentDirectoryURL.path)"
        ]
      )
      // Alternatively, you could try creating intermediate directories:
      // try fileManager.createDirectory(at: parentDirectoryURL, withIntermediateDirectories: true)
      // But this adds complexity and potential side effects. Explicitly requiring the parent is safer.
    }

    // --- Attempt to Create File ---
    do {
      // Convert the initial content string to Data using UTF-8 encoding
      guard let contentData = initialContent.data(using: .utf8) else {
        fputs(
          "ERROR: [CreateFileTool] Failed to encode initial content to UTF-8 data for path: \(filePath)\n",
          stderr)
        throw NSError(
          domain: "CreateFileError",
          code: 500,  // Internal Server Error - Encoding failed
          userInfo: [
            NSLocalizedDescriptionKey:
              "Failed to encode initial content for file '\(relativePath)'."
          ]
        )
      }

      // Create the file with the initial content (or empty data if content was empty)
      let success = fileManager.createFile(atPath: filePath, contents: contentData, attributes: nil)

      if success {
        fputs("SUCCESS: [CreateFileTool] Successfully created file: \(filePath)\n", stderr)
        // Return a success message
        return "Successfully created file: \(relativePath)" as String  // Cast if needed
      } else {
        // createFile returning false usually indicates a permissions issue or other OS-level problem
        fputs(
          "ERROR: [CreateFileTool] FileManager.createFile returned false for path: \(filePath). Check permissions.\n",
          stderr)
        throw NSError(
          domain: "CreateFileError",
          code: 500,  // Internal Server Error - Creation failed
          userInfo: [
            NSLocalizedDescriptionKey:
              "Failed to create file '\(relativePath)' using FileManager. Possible permissions issue. Path: \(filePath)"
          ]
        )
      }

    } catch let error as NSError {
      // Catch errors specifically thrown above or potentially other underlying errors
      fputs(
        "ERROR: [CreateFileTool] Failed to create file at \(filePath): \(error.localizedDescription)\n",
        stderr)
      // Re-throw the caught error
      throw error
    } catch {
      // Catch any other unexpected errors
      fputs(
        "ERROR: [CreateFileTool] An unexpected error occurred while creating file at \(filePath): \(error.localizedDescription)\n",
        stderr)
      throw NSError(
        domain: "CreateFileError",
        code: 500,  // Internal Server Error - Unexpected
        userInfo: [
          NSLocalizedDescriptionKey:
            "An unexpected error occurred while creating file '\(relativePath)': \(error.localizedDescription). Path: \(filePath)"
        ]
      )
    }
  }
}
