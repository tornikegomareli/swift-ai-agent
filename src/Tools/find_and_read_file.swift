//
//  find_and_read_file.swift
//  swift-ai-agent
//
//  Created by Tornike Gomareli on 23.04.25.
//

import Foundation

func createFindAndReadFileTool() -> ToolDefinition {
  // --- Define Input Schema Properties ---
  // `filename`: The name of the file to search for (required).
  let filenameProperty = SchemaProperty(
    type: "string",
    description: "The exact name of the file to search for (e.g., 'main.swift', 'README.md')."
  )
  
  // `search_path`: Optional relative path to start the search from.
  let searchPathProperty = SchemaProperty(
    type: "string",
    description: "Optional. The relative path of the directory where the recursive search should begin. Defaults to the current working directory if omitted."
  )
  
  // `include_hidden_dirs`: Optional flag to search inside hidden directories.
  let includeHiddenDirsProperty = SchemaProperty(
    type: "boolean",
    description: "Optional. Whether to search inside hidden directories (like '.git', '.build'). Defaults to false."
  )
  
  // --- Define the Input Schema ---
  let inputSchema = ToolInputSchema(
    type: "object",
    properties: [
      "filename": filenameProperty,
      "search_path": searchPathProperty,
      "include_hidden_dirs": includeHiddenDirsProperty
    ],
    required: ["filename"] // Only filename is strictly required
  )
  
  // --- Create and Return the ToolDefinition ---
  return ToolDefinition(
    name: "find_and_read_file",
    description: "Recursively searches for a file by its name within a specified directory (or current directory) and returns the content of the first match found. Can optionally search hidden directories.",
    inputSchema: inputSchema
  ) { input in // This is the execution closure
    
    // --- Get Input Parameters ---
    guard let filename = input["filename"] as? String, !filename.isEmpty else {
      throw NSError(
        domain: "ToolError",
        code: 400, // Bad Request
        userInfo: [NSLocalizedDescriptionKey: "Missing or empty required parameter: filename"]
      )
    }
    
    let relativeSearchPath = input["search_path"] as? String
    let shouldSearchHiddenDirs = input["include_hidden_dirs"] as? Bool ?? false // Default to false
    
    let fileManager = FileManager.default
    let currentWorkingDirectory = fileManager.currentDirectoryPath
    let currentWorkingURL = URL(fileURLWithPath: currentWorkingDirectory, isDirectory: true)
    
    // --- Determine Absolute Search Root Directory ---
    let searchRootURL: URL
    if let relPath = relativeSearchPath, !relPath.isEmpty {
      // Resolve provided relative path against CWD
      searchRootURL = URL(fileURLWithPath: relPath, relativeTo: currentWorkingURL).standardizedFileURL
      fputs("DEBUG: [FindAndReadFileTool] Using provided relative search path: \(relPath)\n", stderr)
    } else {
      // Default to CWD
      searchRootURL = currentWorkingURL
      fputs("DEBUG: [FindAndReadFileTool] No search path provided, starting search from CWD.\n", stderr)
    }
    let searchRootPath = searchRootURL.path
    
    // Log details for debugging
    fputs("DEBUG: [FindAndReadFileTool] Agent CWD: \(currentWorkingDirectory)\n", stderr)
    fputs("DEBUG: [FindAndReadFileTool] Searching for filename: '\(filename)'\n", stderr)
    fputs("DEBUG: [FindAndReadFileTool] Starting search in absolute path: \(searchRootPath)\n", stderr)
    fputs("DEBUG: [FindAndReadFileTool] Search hidden directories: \(shouldSearchHiddenDirs)\n", stderr)
    
    
    // --- Validate Search Root Directory ---
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: searchRootPath, isDirectory: &isDirectory), isDirectory.boolValue else {
      fputs("ERROR: [FindAndReadFileTool] Search root path does not exist or is not a directory: \(searchRootPath)\n", stderr)
      throw NSError(
        domain: "FindAndReadFileError",
        code: 404, // Not Found (for the search root)
        userInfo: [NSLocalizedDescriptionKey: "The specified search path '\(relativeSearchPath ?? ".")' does not exist or is not a directory. Full path checked: \(searchRootPath)"]
      )
    }
    
    // --- Perform Recursive Search and Read ---
    // We embed the recursive logic here for self-containment, adapted from previous examples.
    
    // Prepare properties to fetch during enumeration
    let keys: [URLResourceKey] = [.nameKey, .isRegularFileKey, .isDirectoryKey]
    // Basic options: skip hidden *files* by default unless searching hidden *dirs*
    var options: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants]
    if !shouldSearchHiddenDirs {
      // Only skip hidden files if we are NOT searching hidden directories
      // Note: This doesn't skip descending hidden dirs yet, that's handled below.
      options.insert(.skipsHiddenFiles)
    }
    
    
    // Create the enumerator
    guard let enumerator = fileManager.enumerator(
      at: searchRootURL,
      includingPropertiesForKeys: keys,
      options: options,
      errorHandler: { (url, error) -> Bool in
        // Log errors during enumeration but try to continue
        fputs("WARNING: [FindAndReadFileTool] Error accessing \(url.path): \(error.localizedDescription). Skipping item.\n", stderr)
        return true
      }
    ) else {
      fputs("ERROR: [FindAndReadFileTool] Could not create directory enumerator for '\(searchRootPath)'.\n", stderr)
      throw NSError(
        domain: "FindAndReadFileError",
        code: 500, // Internal error
        userInfo: [NSLocalizedDescriptionKey: "Failed to start searching directory: \(searchRootPath)"]
      )
    }
    
    // Iterate through the file system hierarchy
    for case let fileURL as URL in enumerator {
      do {
        let resourceValues = try fileURL.resourceValues(forKeys: Set(keys))
        
        // --- Skip Hidden Directories if requested ---
        if !shouldSearchHiddenDirs {
          if let isDir = resourceValues.isDirectory, isDir,
             let name = resourceValues.name, name.starts(with: ".") {
            enumerator.skipDescendants() // Tell enumerator to skip contents of this dir
            // fputs("DEBUG: [FindAndReadFileTool] Skipping hidden directory: \(fileURL.path)\n", stderr) // Optional debug log
            continue // Move to the next item from the enumerator
          }
        }
        // --- End Hidden Directory Check ---
        
        // --- Check if it's the target regular file ---
        if let isRegular = resourceValues.isRegularFile, isRegular,
           let name = resourceValues.name, name == filename {
          
          // Found the file! Attempt to read it.
          fputs("DEBUG: [FindAndReadFileTool] Found potential match at: \(fileURL.path)\n", stderr)
          do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            fputs("SUCCESS: [FindAndReadFileTool] Successfully read content from: \(fileURL.path)\n", stderr)
            return content as Any as! String
          } catch {
            // Found the file but couldn't read it. Log and throw.
            fputs("ERROR: [FindAndReadFileTool] Found file '\(filename)' at \(fileURL.path), but failed to read content: \(error.localizedDescription)\n", stderr)
            throw NSError(
              domain: "FindAndReadFileError",
              code: 500, // Internal Error / Read Failed
              userInfo: [NSLocalizedDescriptionKey: "Found file '\(filename)' but failed to read its content: \(error.localizedDescription). Path: \(fileURL.path)"]
            )
          }
        }
        // --- End Target File Check ---
        
      } catch {
        // Error getting properties for a specific item, log and continue search
        fputs("WARNING: [FindAndReadFileTool] Error getting properties for \(fileURL.path): \(error.localizedDescription). Skipping item.\n", stderr)
        continue
      }
    } // End of enumeration loop
    
    // --- File Not Found ---
    // If the loop completes without returning/throwing, the file wasn't found.
    fputs("INFO: [FindAndReadFileTool] File '\(filename)' not found within search path '\(searchRootPath)' (hidden dirs searched: \(shouldSearchHiddenDirs)).\n", stderr)
    throw NSError(
      domain: "FindAndReadFileError",
      code: 404, // Not Found
      userInfo: [NSLocalizedDescriptionKey: "File '\(filename)' not found within the specified search parameters."]
    )
  }
}
