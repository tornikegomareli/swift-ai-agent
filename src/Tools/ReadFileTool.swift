//
//  ReadFileTool.swift
//  swift-ai-agent
//
//  Created by Tornike Gomareli on 22.04.25.
//

import Claude
import Foundation

// Tool definitions using the @Tool macro as described in the README
@Tool
struct ReadFileTool {
  /// Read the contents of a given relative file path.
  /// Use this when you want to see what's inside a file.
  /// Do not use this with directory names.
  func invoke(path: String) throws -> String {
    let fileManager = FileManager.default
    let currentPath = fileManager.currentDirectoryPath
    let filePath = currentPath + "/" + path
    
    guard let fileContents = try? String(contentsOfFile: filePath, encoding: .utf8) else {
      throw NSError(
        domain: "FileError", code: 2,
        userInfo: [NSLocalizedDescriptionKey: "Could not read file: \(path)"])
    }
    
    return fileContents
  }
}

@Tool
struct ListFilesTool {
  /// List files and directories at a given path.
  /// If no path is provided, lists files in the current directory.
  func invoke(path: String? = nil) throws -> String {
    let pathToList = path ?? "."
    let fileManager = FileManager.default
    let currentPath = fileManager.currentDirectoryPath
    let directoryPath = currentPath + "/" + pathToList
    
    var files: [String] = []
    
    do {
      let items = try fileManager.contentsOfDirectory(atPath: directoryPath)
      
      for item in items {
        var isDir: ObjCBool = false
        let itemPath = directoryPath + "/" + item
        if fileManager.fileExists(atPath: itemPath, isDirectory: &isDir) {
          if isDir.boolValue {
            files.append(item + "/")
          } else {
            files.append(item)
          }
        }
      }
    } catch {
      throw error
    }
    
    return files.joined(separator: "\n")
  }
}

@Tool
struct EditFileTool {
  /// Make edits to a text file.
  ///
  /// Replaces 'old_str' with 'new_str' in the given file.
  /// If the file specified with path doesn't exist, it will be created.
  func invoke(path: String, old_str: String, new_str: String) throws -> String {
    if path.isEmpty || old_str == new_str {
      throw NSError(
        domain: "InvalidInput", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Invalid input parameters"])
    }
    
    let fileManager = FileManager.default
    let currentPath = fileManager.currentDirectoryPath
    let filePath = currentPath + "/" + path
    
    // Check if file exists
    if !fileManager.fileExists(atPath: filePath) {
      // If file doesn't exist and oldStr is empty, create a new file
      if old_str.isEmpty {
        return try createNewFile(filePath: filePath, content: new_str)
      } else {
        throw NSError(
          domain: "FileError", code: 2,
          userInfo: [NSLocalizedDescriptionKey: "File doesn't exist: \(path)"])
      }
    }
    
    // Read file content
    guard let fileContent = try? String(contentsOfFile: filePath, encoding: .utf8) else {
      throw NSError(
        domain: "FileError", code: 2,
        userInfo: [NSLocalizedDescriptionKey: "Could not read file: \(path)"])
    }
    
    // Replace string
    let newContent = fileContent.replacingOccurrences(of: old_str, with: new_str)
    
    // Check if anything was replaced
    if newContent == fileContent && !old_str.isEmpty {
      throw NSError(
        domain: "EditError", code: 3,
        userInfo: [NSLocalizedDescriptionKey: "old_str not found in file"])
    }
    
    // Write back to file
    do {
      try newContent.write(toFile: filePath, atomically: true, encoding: .utf8)
      return "OK"
    } catch {
      throw NSError(
        domain: "FileError", code: 4,
        userInfo: [
          NSLocalizedDescriptionKey: "Failed to write to file: \(error.localizedDescription)"
        ])
    }
  }
  
  private func createNewFile(filePath: String, content: String) throws -> String {
    let fileManager = FileManager.default
    let directory = (filePath as NSString).deletingLastPathComponent
    
    // Create directory if it doesn't exist
    if directory != "." && !fileManager.fileExists(atPath: directory) {
      try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true)
    }
    
    // Create file
    try content.write(toFile: filePath, atomically: true, encoding: .utf8)
    
    return "Successfully created file \(filePath)"
  }
}
