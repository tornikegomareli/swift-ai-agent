//
//  find_file_in_directory.swift
//  swift-ai-agent
//
//  Created by Tornike Gomareli on 23.04.25.
//

import Foundation

/// Finds the first occurrence of a file with the specified name recursively
/// within a given root directory and prints its full path.
///
/// - Parameters:
///   - filename: The name of the file to search for (e.g., "main.swift").
///   - rootDirectoryPath: The absolute or relative path to the directory
///     where the search should begin.
func findFile(named filename: String, in rootDirectoryPath: String) -> URL? {
  let fileManager = FileManager.default
  // Create a URL for the root directory. Using URLs is generally preferred
  // over string paths with FileManager.
  let rootURL = URL(fileURLWithPath: rootDirectoryPath)
  
  // 1. Check if the root path is valid and is a directory
  var isDirectory: ObjCBool = false
  guard fileManager.fileExists(atPath: rootURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
    // Use stderr for error messages in command-line tools
    fputs("Error: Root path '\(rootDirectoryPath)' does not exist or is not a directory.\n", stderr)
    return nil
  }
  
  // 2. Prepare properties to fetch and options for enumeration
  // Fetching `nameKey` and `isRegularFileKey` avoids extra file system calls later.
  let keys: [URLResourceKey] = [.nameKey, .isRegularFileKey]
  // `.skipsHiddenFiles` is often desirable.
  // `.skipsPackageDescendants` prevents descending into bundles like .app or .framework.
  let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants]
  
  // 3. Create the directory enumerator
  // This enumerator performs a deep traversal (goes into subdirectories).
  guard let enumerator = fileManager.enumerator(
    at: rootURL,
    includingPropertiesForKeys: keys,
    options: options,
    errorHandler: { (url, error) -> Bool in
      // Handle errors during enumeration (e.g., permission denied)
      fputs("Error accessing \(url.path): \(error.localizedDescription)\n", stderr)
      // Returning true tells the enumerator to attempt to continue
      return true
    }
  ) else {
    fputs("Error: Could not create directory enumerator for '\(rootDirectoryPath)'.\n", stderr)
    return nil
  }
  
  // 4. Iterate through the enumerated contents
  var found = false
  for case let fileURL as URL in enumerator {
    do {
      // Get the pre-fetched resource values
      let resourceValues = try fileURL.resourceValues(forKeys: Set(keys))
      
      // Check if it's a regular file (not a directory, symlink, etc.)
      // AND if the name matches the target filename.
      if let isRegularFile = resourceValues.isRegularFile,
         isRegularFile,
         let name = resourceValues.name,
         name == filename {
        
        
        found = true
        return fileURL
      }
    } catch {
      fputs("Error getting properties for \(fileURL.path): \(error.localizedDescription)\n", stderr)
      // Continue to the next item even if properties couldn't be read for one item.
      continue
    }
  }
  
  // 5. If the loop finished without finding the file (and we didn't return early)
  if !found {
    print("File '\(filename)' not found within '\(rootDirectoryPath)' or its subdirectories.")
    return nil
  }
}

/// Finds the first occurrence of a file with the specified name recursively
/// within a given root directory and returns its content as a String.
/// Skips descending into hidden directories (those starting with '.').
///
/// - Parameters:
///   - filename: The name of the file to search for (e.g., "main.swift").
///   - rootDirectoryPath: The absolute or relative path to the directory
///     where the search should begin.
/// - Returns: The content of the found file as a String using UTF-8 encoding,
///   or `nil` if the file is not found, cannot be read, or the search encounters
///   critical errors.
func findAndReadFileContent(named filename: String, in rootDirectoryPath: String) -> String? {
  let fileManager = FileManager.default
  let rootURL = URL(fileURLWithPath: rootDirectoryPath)
  
  // 1. Validate root directory
  var isDirectory: ObjCBool = false
  guard fileManager.fileExists(atPath: rootURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
    fputs("Error: Root path '\(rootDirectoryPath)' does not exist or is not a directory.\n", stderr)
    return nil
  }
  
  // 2. Prepare properties to fetch: Add `.isDirectoryKey`
  // We need to know if an item is a directory to decide whether to skip its descendants.
  let keys: [URLResourceKey] = [.nameKey, .isRegularFileKey, .isDirectoryKey]
  // Keep `.skipsHiddenFiles` to skip hidden *files* themselves (like .DS_Store)
  // Keep `.skipsPackageDescendants` for bundles
  let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants]
  
  // 3. Create the directory enumerator
  guard let enumerator = fileManager.enumerator(
    at: rootURL,
    includingPropertiesForKeys: keys,
    options: options,
    errorHandler: { (url, error) -> Bool in
      fputs("Error accessing \(url.path): \(error.localizedDescription)\n", stderr)
      return true // Continue enumeration
    }
  ) else {
    fputs("Error: Could not create directory enumerator for '\(rootDirectoryPath)'.\n", stderr)
    return nil
  }
  
  // 4. Iterate and search
  for case let fileURL as URL in enumerator {
    do {
      // Get the pre-fetched resource values
      let resourceValues = try fileURL.resourceValues(forKeys: Set(keys))
      
      // --- Check if it's a HIDDEN DIRECTORY ---
      // If it's a directory AND its name starts with '.', skip its contents.
      if let isDirectory = resourceValues.isDirectory,
         isDirectory,
         let name = resourceValues.name,
         name.starts(with: ".") {
        
        // Tell the enumerator NOT to descend into this directory
        enumerator.skipDescendants()
        // print("Skipping hidden directory: \(fileURL.path)") // Optional: for debugging
        
        // Continue to the next item provided by the enumerator
        // (which will now be outside the skipped directory)
        continue
      }
      // --- End Hidden Directory Check ---
      
      
      // --- Check if it's the TARGET REGULAR FILE ---
      // This part only runs if it wasn't a hidden directory
      if let isRegularFile = resourceValues.isRegularFile,
         isRegularFile,
         let name = resourceValues.name,
         name == filename {
        
        // Found the file: Attempt to read its content
        do {
          let content = try String(contentsOf: fileURL, encoding: .utf8)
          // print("Found file at: \(fileURL.path)") // Optional: for debugging
          return content // Return the content, stopping the search.
        } catch {
          fputs("Error: Found file '\(filename)' at \(fileURL.path), but failed to read its content: \(error.localizedDescription)\n", stderr)
          return nil // Stop searching, return nil on read error
        }
      }
      // --- End Target File Check ---
      
    } catch {
      // Handle errors getting properties for a specific item
      fputs("Error getting properties for \(fileURL.path): \(error.localizedDescription)\n", stderr)
      // Continue searching with the next item
      continue
    }
  }
  
  // 5. If the loop finishes without finding the file
  print("File '\(filename)' not found (excluding hidden directories) within '\(rootDirectoryPath)'.")
  return nil
}
