import Foundation

extension FileManager {
    func makeRelativeToCurrentDirectory(path: String) -> URL {
        URL(fileURLWithPath: path, relativeTo: URL(fileURLWithPath: currentDirectoryPath)).standardizedFileURL
    }
}
