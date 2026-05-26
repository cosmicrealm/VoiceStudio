import CryptoKit
import Foundation

public struct SpeechTokenizerNormalizationResult: Equatable, Sendable {
    public let normalizedModels: Int
    public let sharedCopies: Int

    public static let empty = SpeechTokenizerNormalizationResult(normalizedModels: 0, sharedCopies: 0)
}

public enum SpeechTokenizerStore {
    public static func normalize(
        in modelsDirectory: URL,
        fileManager: FileManager = .default
    ) throws -> SpeechTokenizerNormalizationResult {
        let sharedRoot = modelsDirectory
            .appendingPathComponent("shared", isDirectory: true)
            .appendingPathComponent("speech_tokenizer", isDirectory: true)
        guard let modelDirectories = try? fileManager.contentsOfDirectory(
            at: modelsDirectory,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles]
        ) else {
            return .empty
        }

        var normalized = 0
        var sharedCopies = 0
        for modelDirectory in modelDirectories where modelDirectory.lastPathComponent != "shared" {
            let values = try modelDirectory.resourceValues(forKeys: [.isDirectoryKey])
            guard values.isDirectory == true else { continue }

            let tokenizerDirectory = modelDirectory.appendingPathComponent("speech_tokenizer", isDirectory: true)
            let tokenizerValues = try? tokenizerDirectory.resourceValues(forKeys: [.isSymbolicLinkKey])
            let isTokenizerSymlink = tokenizerValues?.isSymbolicLink == true
            guard isTokenizerSymlink || fileManager.fileExists(atPath: tokenizerDirectory.path) else { continue }
            if isTokenizerSymlink {
                if try repairSharedSymlinkIfNeeded(
                    tokenizerDirectory: tokenizerDirectory,
                    sharedRoot: sharedRoot,
                    fileManager: fileManager
                ) {
                    normalized += 1
                }
                continue
            }
            guard fileManager.fileExists(atPath: tokenizerDirectory.appendingPathComponent("model.safetensors").path) else {
                continue
            }

            let hash = try tokenizerHash(for: tokenizerDirectory, fileManager: fileManager)
            let sharedTokenizer = sharedRoot.appendingPathComponent(hash, isDirectory: true)
            if !fileManager.fileExists(atPath: sharedTokenizer.path) {
                try fileManager.createDirectory(at: sharedRoot, withIntermediateDirectories: true)
                try fileManager.copyItem(at: tokenizerDirectory, to: sharedTokenizer)
                sharedCopies += 1
            }

            try replaceWithSharedTokenizer(
                tokenizerDirectory: tokenizerDirectory,
                sharedTokenizer: sharedTokenizer,
                fileManager: fileManager
            )
            normalized += 1
        }
        try cleanupEmptySharedTokenizers(sharedRoot: sharedRoot, fileManager: fileManager)
        return SpeechTokenizerNormalizationResult(normalizedModels: normalized, sharedCopies: sharedCopies)
    }

    private static func repairSharedSymlinkIfNeeded(
        tokenizerDirectory: URL,
        sharedRoot: URL,
        fileManager: FileManager
    ) throws -> Bool {
        let destination = try fileManager.destinationOfSymbolicLink(atPath: tokenizerDirectory.path)
        let destinationURL = URL(fileURLWithPath: destination, relativeTo: tokenizerDirectory.deletingLastPathComponent()).standardizedFileURL
        if fileManager.fileExists(atPath: destinationURL.appendingPathComponent("model.safetensors").path) {
            return false
        }
        let localSharedTokenizer = sharedRoot.appendingPathComponent(destinationURL.lastPathComponent, isDirectory: true)
        if fileManager.fileExists(atPath: localSharedTokenizer.appendingPathComponent("model.safetensors").path) {
            try replaceWithSharedTokenizer(
                tokenizerDirectory: tokenizerDirectory,
                sharedTokenizer: localSharedTokenizer,
                fileManager: fileManager
            )
            return true
        }
        if let onlySharedTokenizer = try singleValidSharedTokenizer(in: sharedRoot, fileManager: fileManager) {
            try replaceWithSharedTokenizer(
                tokenizerDirectory: tokenizerDirectory,
                sharedTokenizer: onlySharedTokenizer,
                fileManager: fileManager
            )
            return true
        }
        if destinationURL.path.hasPrefix(sharedRoot.standardizedFileURL.path) {
            try fileManager.removeItem(at: tokenizerDirectory)
        }
        return false
    }

    private static func tokenizerHash(for tokenizerDirectory: URL, fileManager: FileManager) throws -> String {
        let weights = tokenizerDirectory.appendingPathComponent("model.safetensors")
        let digest = try sha256(url: weights)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    private static func cleanupEmptySharedTokenizers(sharedRoot: URL, fileManager: FileManager) throws {
        guard let children = try? fileManager.contentsOfDirectory(at: sharedRoot, includingPropertiesForKeys: [.isDirectoryKey]) else {
            return
        }
        for child in children {
            let weights = child.appendingPathComponent("model.safetensors")
            if !fileManager.fileExists(atPath: weights.path) {
                try? fileManager.removeItem(at: child)
            }
        }
    }

    private static func singleValidSharedTokenizer(in sharedRoot: URL, fileManager: FileManager) throws -> URL? {
        guard let children = try? fileManager.contentsOfDirectory(at: sharedRoot, includingPropertiesForKeys: [.isDirectoryKey]) else {
            return nil
        }
        let valid = children.filter { child in
            fileManager.fileExists(atPath: child.appendingPathComponent("model.safetensors").path)
        }
        return valid.count == 1 ? valid[0] : nil
    }

    private static func sha256(url: URL) throws -> SHA256.Digest {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while autoreleasepool(invoking: {
            let chunk = handle.readData(ofLength: 4 * 1024 * 1024)
            guard !chunk.isEmpty else { return false }
            hasher.update(data: chunk)
            return true
        }) {}
        return hasher.finalize()
    }

    private static func replaceWithSharedTokenizer(
        tokenizerDirectory: URL,
        sharedTokenizer: URL,
        fileManager: FileManager
    ) throws {
        try fileManager.removeItem(at: tokenizerDirectory)
        do {
            try fileManager.createSymbolicLink(at: tokenizerDirectory, withDestinationURL: sharedTokenizer)
        } catch {
            try fileManager.copyItem(at: sharedTokenizer, to: tokenizerDirectory)
        }
    }
}
