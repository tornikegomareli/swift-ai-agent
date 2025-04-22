//
//  list_files_tool.swift
//  swift-ai-agent
//
//  Created by Tornike Gomareli on 23.04.25.
//

import Foundation

/// Creates a ToolDefinition for listing files and directories within a specified path.
///
/// This tool allows an AI agent to inspect the contents of the file system
/// relative to its current working directory.
func createListFilesTool() -> ToolDefinition {
  
  // Define the 'path' property: Optional relative directory path.
  let pathProperty = SchemaProperty(
    type: "string",
    description: "Optional. The relative path of the directory to list. Defaults to the current working directory if omitted."
  )
  
  // Define the 'include_hidden' property: Optional boolean flag.
  let includeHiddenProperty = SchemaProperty(
    type: "boolean",
    description: "Optional. Whether to include hidden files and directories (starting with '.'). Defaults to false."
  )
  
  // Define the input schema using the properties. 'path' is not required.
  let inputSchema = ToolInputSchema(
    type: "object",
    properties: [
      "path": pathProperty,
      "include_hidden": includeHiddenProperty
    ],
    required: nil // No properties are strictly required
  )
  
  // Create and return the ToolDefinition
  return ToolDefinition(
    name: "list_files",
    description: "Lists the files and directories within a specified relative path. Defaults to the current working directory.",
    inputSchema: inputSchema
  ) { input in // This is the execution closure
    
    let fileManager = FileManager.default
    let currentWorkingDirectory = fileManager.currentDirectoryPath
    
    // --- Determine Target Directory ---
    let relativePath = input["path"] as? String // Get optional path input
    let targetDirectoryPath: String
    let targetDirectoryURL: URL
    
    if let relPath = relativePath, !relPath.isEmpty {
      // If a path was provided, resolve it relative to the CWD
      let currentWorkingURL = URL(fileURLWithPath: currentWorkingDirectory, isDirectory: true)
      targetDirectoryURL = URL(fileURLWithPath: relPath, relativeTo: currentWorkingURL).standardizedFileURL
      targetDirectoryPath = targetDirectoryURL.path
      fputs("DEBUG: [ListFilesTool] Using provided relative path: \(relPath)\n", stderr)
    } else {
      // If no path provided or it's empty, use the CWD
      targetDirectoryPath = currentWorkingDirectory
      targetDirectoryURL = URL(fileURLWithPath: targetDirectoryPath, isDirectory: true)
      fputs("DEBUG: [ListFilesTool] No path provided, using CWD.\n", stderr)
    }
    
    // Log the CWD and the final path being listed for debugging
    fputs("DEBUG: [ListFilesTool] Agent CWD: \(currentWorkingDirectory)\n", stderr)
    fputs("DEBUG: [ListFilesTool] Listing contents of absolute path: \(targetDirectoryPath)\n", stderr)
    
    // --- Validate Target Directory ---
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: targetDirectoryPath, isDirectory: &isDirectory) else {
      fputs("ERROR: [ListFilesTool] Target path does not exist: \(targetDirectoryPath)\n", stderr)
      throw NSError(
        domain: "ListFilesError",
        code: 404, // Not Found
        userInfo: [NSLocalizedDescriptionKey: "The specified path '\(relativePath ?? ".")' does not exist. Full path checked: \(targetDirectoryPath)"]
      )
    }
    guard isDirectory.boolValue else {
      fputs("ERROR: [ListFilesTool] Target path is not a directory: \(targetDirectoryPath)\n", stderr)
      throw NSError(
        domain: "ListFilesError",
        code: 400, // Bad Request
        userInfo: [NSLocalizedDescriptionKey: "The specified path '\(relativePath ?? ".")' is not a directory. Full path checked: \(targetDirectoryPath)"]
      )
    }
    
    // --- List Directory Contents ---
    do {
      // Determine whether to include hidden files based on input or default (false)
      let includeHidden = input["include_hidden"] as? Bool ?? false
      fputs("DEBUG: [ListFilesTool] Include hidden files: \(includeHidden)\n", stderr)
      
      // Get contents. Note: contentsOfDirectory(atPath:) doesn't provide URLs directly here.
      var contents = try fileManager.contentsOfDirectory(atPath: targetDirectoryPath)
      
      // Filter hidden files if necessary
      if !includeHidden {
        contents = contents.filter { !$0.starts(with: ".") }
      }
      
      // Optional: Add indicator for directories (e.g., append '/')
      // This requires an extra check for each item, potentially slower for large directories.
      let detailedContents = contents.map { itemName -> String in
        let itemURL = targetDirectoryURL.appendingPathComponent(itemName)
        var itemIsDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: itemURL.path, isDirectory: &itemIsDirectory), itemIsDirectory.boolValue {
          return itemName + "/" // Append slash to indicate directory
        } else {
          return itemName // Just the filename
        }
      }
      
      
      // Format the output: Newline-separated string is often easy for LLMs
      let outputString = detailedContents.joined(separator: "\n")
      
      fputs("SUCCESS: [ListFilesTool] Listed contents of \(targetDirectoryPath)\n", stderr) // Debug log
      
      // Return the formatted list
      // Note: Ensure the expected return type matches your ToolDefinition handler signature (Any, String, etc.)
      return outputString as Any as! String // Cast to Any if your handler returns Any
      
    } catch {
      // Handle errors during directory listing (e.g., permissions)
      fputs("ERROR: [ListFilesTool] Failed to list contents of \(targetDirectoryPath): \(error.localizedDescription)\n", stderr)
      throw NSError(
        domain: "ListFilesError",
        code: 500, // Internal Server Error / Failed Operation
        userInfo: [NSLocalizedDescriptionKey: "Failed to list directory contents for '\(relativePath ?? ".")': \(error.localizedDescription). Full path: \(targetDirectoryPath)"]
      )
    }
  }
}

// --- Example Usage (within your agent setup) ---
/*
 // Assuming you have an Agent class or similar setup
 let listTool = createListFilesTool()
 // Register the tool with your agent
 agent.registerTool(listTool)
 
 // When the agent decides to use the tool, it will call the `execute` closure
 // with input like: ["path": "Sources/Utils", "include_hidden": true] or just [:]
 */
