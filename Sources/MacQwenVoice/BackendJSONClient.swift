import Foundation

final class BackendJSONClient {
    private let backendScript: URL
    private let dataDirectory: URL
    private let pythonExecutable: URL
    private let lock = NSLock()
    private var process: Process?
    private var inputHandle: FileHandle?
    private var outputHandle: FileHandle?
    private var errorHandle: FileHandle?
    private var nextRequestID = 1

    init(
        backendScript: URL = BackendJSONClient.defaultBackendScript(),
        dataDirectory: URL,
        pythonExecutable: URL = BackendJSONClient.defaultPythonExecutable()
    ) {
        self.backendScript = backendScript
        self.dataDirectory = dataDirectory
        self.pythonExecutable = pythonExecutable
    }

    deinit {
        stop()
    }

    func oneShot(method: String, params: [String: Any] = [:]) throws -> [String: Any] {
        try request(method: method, params: params)
    }

    func request(method: String, params: [String: Any] = [:]) throws -> [String: Any] {
        lock.lock()
        defer { lock.unlock() }

        try startIfNeeded()
        guard let inputHandle, let outputHandle else {
            throw BackendClientError.processFailed("Backend pipe is not available.")
        }

        let requestID = nextRequestID
        nextRequestID += 1
        let request: [String: Any] = ["jsonrpc": "2.0", "id": requestID, "method": method, "params": params]
        let payload = try JSONSerialization.data(withJSONObject: request)
        inputHandle.write(payload)
        inputHandle.write(Data("\n".utf8))

        while true {
            let line = try readLine(from: outputHandle)
            guard let payload = try JSONSerialization.jsonObject(with: line) as? [String: Any] else {
                throw BackendClientError.invalidResponse(String(data: line, encoding: .utf8) ?? "")
            }
            if let id = payload["id"] as? Int, id == requestID {
                if payload["error"] != nil {
                    throw BackendClientError.invalidResponse(String(data: line, encoding: .utf8) ?? "")
                }
                return payload
            }
        }
    }

    func stop() {
        lock.lock()
        defer { lock.unlock() }
        inputHandle?.closeFile()
        outputHandle?.closeFile()
        errorHandle?.closeFile()
        if let process, process.isRunning {
            process.terminate()
        }
        process = nil
        inputHandle = nil
        outputHandle = nil
        errorHandle = nil
    }

    private func startIfNeeded() throws {
        if let process, process.isRunning {
            return
        }
        let process = Process()
        process.executableURL = pythonExecutable
        process.arguments = [
            backendScript.path,
            "--data-dir",
            dataDirectory.path,
            "--parent-pid",
            "\(ProcessInfo.processInfo.processIdentifier)"
        ]

        let input = Pipe()
        let output = Pipe()
        let error = Pipe()
        process.standardInput = input
        process.standardOutput = output
        process.standardError = error
        process.environment = VoiceStudioRuntimeEnvironment.mergedEnvironment()

        try process.run()
        self.process = process
        inputHandle = input.fileHandleForWriting
        outputHandle = output.fileHandleForReading
        errorHandle = error.fileHandleForReading
    }

    private func readLine(from handle: FileHandle) throws -> Data {
        var data = Data()
        while true {
            let chunk = handle.readData(ofLength: 1)
            if chunk.isEmpty {
                let stderr = errorHandle.map { String(data: $0.readDataToEndOfFile(), encoding: .utf8) ?? "" } ?? ""
                throw BackendClientError.processFailed(stderr.isEmpty ? "Backend process closed stdout." : stderr)
            }
            if chunk == Data("\n".utf8) {
                return data
            }
            data.append(chunk)
        }
    }

    static func defaultBackendScript() -> URL {
        let current = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("backend/server.py")
        if FileManager.default.fileExists(atPath: current.path) {
            return current
        }
        if let resource = Bundle.main.resourceURL?.appendingPathComponent("backend/server.py"),
           FileManager.default.fileExists(atPath: resource.path) {
            return resource
        }
        return current
    }

    static func defaultPythonExecutable() -> URL {
        if let override = ProcessInfo.processInfo.environment["MACQWENVOICE_PYTHON"],
           FileManager.default.isExecutableFile(atPath: override) {
            return URL(fileURLWithPath: override)
        }
        if let bundled = VoiceStudioRuntimeEnvironment.bundledRuntimePythonExecutable {
            return bundled
        }
        if let runtime = VoiceStudioRuntimeEnvironment.runtimePythonExecutable {
            return runtime
        }
        if let pathPython = executableFromPath(named: "python3") {
            return pathPython
        }
        let candidates = [
            "/opt/homebrew/bin/python3",
            "/usr/local/bin/python3",
            "/usr/bin/python3"
        ]
        if let path = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            return URL(fileURLWithPath: path)
        }
        return URL(fileURLWithPath: "/usr/bin/python3")
    }

    private static func executableFromPath(named name: String) -> URL? {
        VoiceStudioRuntimeEnvironment.executableFromPath(named: name)
    }
}

extension BackendJSONClient: @unchecked Sendable {}

enum BackendClientError: Error, LocalizedError {
    case processFailed(String)
    case invalidResponse(String)

    var errorDescription: String? {
        switch self {
        case .processFailed(let message):
            "Python backend failed: \(message)"
        case .invalidResponse(let payload):
            "Invalid backend response: \(payload)"
        }
    }
}
