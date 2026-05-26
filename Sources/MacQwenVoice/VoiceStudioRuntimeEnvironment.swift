import Foundation

enum VoiceStudioRuntimeEnvironment {
    static var applicationSupportDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("VoiceStudio", isDirectory: true)
            ?? URL(fileURLWithPath: NSHomeDirectory())
                .appendingPathComponent("Library/Application Support/VoiceStudio", isDirectory: true)
    }

    static var runtimeDirectory: URL {
        if let override = ProcessInfo.processInfo.environment["VOICE_STUDIO_RUNTIME_DIR"],
           !override.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return URL(fileURLWithPath: override)
        }
        return applicationSupportDirectory.appendingPathComponent("runtime", isDirectory: true)
    }

    static var runtimeBinDirectory: URL {
        runtimeDirectory.appendingPathComponent("bin", isDirectory: true)
    }

    static var runtimeVenvBinDirectory: URL {
        runtimeDirectory.appendingPathComponent("venv/bin", isDirectory: true)
    }

    static var runtimePythonExecutable: URL? {
        let candidate = runtimeVenvBinDirectory.appendingPathComponent("python3")
        return FileManager.default.isExecutableFile(atPath: candidate.path) ? candidate : nil
    }

    static var bundledRuntimeBinDirectory: URL? {
        Bundle.main.resourceURL?.appendingPathComponent("runtime/bin", isDirectory: true)
    }

    static var bundledRuntimePythonExecutable: URL? {
        guard let resourceURL = Bundle.main.resourceURL else { return nil }
        let candidate = resourceURL.appendingPathComponent("runtime/venv/bin/python3")
        return FileManager.default.isExecutableFile(atPath: candidate.path) ? candidate : nil
    }

    static var installScriptURL: URL? {
        let local = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("scripts/install_runtime.sh")
        if FileManager.default.isExecutableFile(atPath: local.path) {
            return local
        }
        if let resource = Bundle.main.resourceURL?.appendingPathComponent("scripts/install_runtime.sh"),
           FileManager.default.isExecutableFile(atPath: resource.path) {
            return resource
        }
        return nil
    }

    static func executableURL(named name: String) -> URL? {
        var candidates: [URL] = []
        candidates.append(runtimeVenvBinDirectory.appendingPathComponent(name))
        candidates.append(runtimeBinDirectory.appendingPathComponent(name))
        if let bundledRuntimeBinDirectory {
            candidates.append(bundledRuntimeBinDirectory.appendingPathComponent(name))
        }
        candidates.append(URL(fileURLWithPath: "/opt/homebrew/bin/\(name)"))
        candidates.append(URL(fileURLWithPath: "/usr/local/bin/\(name)"))
        candidates.append(URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("opt/anaconda3/bin/\(name)"))
        candidates.append(URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("anaconda3/bin/\(name)"))
        candidates.append(URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("miniconda3/bin/\(name)"))
        for candidate in candidates where FileManager.default.isExecutableFile(atPath: candidate.path) {
            return candidate
        }
        return executableFromPath(named: name)
    }

    static func mergedEnvironment(extra: [String: String] = [:]) -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        environment["VOICE_STUDIO_APP_SUPPORT_DIR"] = applicationSupportDirectory.path
        environment["VOICE_STUDIO_RUNTIME_DIR"] = runtimeDirectory.path
        environment["HF_HUB_ENABLE_HF_TRANSFER"] = environment["HF_HUB_ENABLE_HF_TRANSFER"] ?? "1"

        var pathParts: [String] = [
            runtimeVenvBinDirectory.path,
            runtimeBinDirectory.path,
            "/opt/homebrew/bin",
            "/usr/local/bin",
            URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("opt/anaconda3/bin").path,
            URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("anaconda3/bin").path,
            URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("miniconda3/bin").path,
        ]
        if let bundledRuntimeBinDirectory {
            pathParts.append(bundledRuntimeBinDirectory.path)
        }

        if let existing = environment["PATH"], !existing.isEmpty {
            pathParts.append(existing)
        }
        environment["PATH"] = pathParts.joined(separator: ":")
        extra.forEach { key, value in
            environment[key] = value
        }
        return environment
    }

    static func executableFromPath(named name: String) -> URL? {
        let pathValue = ProcessInfo.processInfo.environment["PATH"] ?? ""
        for directory in pathValue.split(separator: ":") {
            let candidate = URL(fileURLWithPath: String(directory)).appendingPathComponent(name)
            if FileManager.default.isExecutableFile(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }
}
