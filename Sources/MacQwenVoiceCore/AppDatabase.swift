import Foundation
import SQLite3

public enum AppDatabaseError: Error, LocalizedError {
    case openFailed(String)
    case prepareFailed(String)
    case executeFailed(String)

    public var errorDescription: String? {
        switch self {
        case .openFailed(let message), .prepareFailed(let message), .executeFailed(let message):
            message
        }
    }
}

public final class AppDatabase {
    private let db: OpaquePointer?

    public init(path: String) throws {
        let directory = URL(fileURLWithPath: path).deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var handle: OpaquePointer?
        guard sqlite3_open(path, &handle) == SQLITE_OK else {
            let message = handle.flatMap { sqlite3_errmsg($0).map(String.init(cString:)) } ?? "Unable to open SQLite database"
            sqlite3_close(handle)
            throw AppDatabaseError.openFailed(message)
        }
        db = handle
        try migrate()
    }

    deinit {
        sqlite3_close(db)
    }

    public func saveVoice(_ voice: VoiceProfile) throws -> String {
        try execute(
            """
            INSERT OR REPLACE INTO voices
            (id, name, kind, language, speaker, instruct, reference_audio_path, reference_text, consent_id, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [
                .text(voice.id),
                .text(voice.name),
                .text(voice.kind.rawValue),
                .text(voice.language),
                .optionalText(voice.speaker),
                .text(voice.instruct),
                .optionalText(voice.referenceAudioPath),
                .optionalText(voice.referenceText),
                .optionalText(voice.consentID),
                .double(voice.createdAt.timeIntervalSince1970)
            ]
        )
        return voice.id
    }

    public func listVoices() throws -> [VoiceProfile] {
        try query(
            """
            SELECT id, name, kind, language, speaker, instruct, reference_audio_path, reference_text, consent_id, created_at
            FROM voices ORDER BY created_at ASC
            """
        ) { statement in
            VoiceProfile(
                id: Self.text(statement, 0),
                name: Self.text(statement, 1),
                kind: VoiceKind(rawValue: Self.text(statement, 2)) ?? .customVoice,
                language: Self.text(statement, 3),
                speaker: Self.optionalText(statement, 4),
                instruct: Self.text(statement, 5),
                referenceAudioPath: Self.optionalText(statement, 6),
                referenceText: Self.optionalText(statement, 7),
                consentID: Self.optionalText(statement, 8),
                createdAt: Date(timeIntervalSince1970: Self.double(statement, 9))
            )
        }
    }

    public func saveModelState(_ state: ModelState) throws {
        try execute(
            """
            INSERT OR REPLACE INTO models (id, local_path, status, bytes)
            VALUES (?, ?, ?, ?)
            """,
            [
                .text(state.id),
                .optionalText(state.localPath),
                .text(state.status.rawValue),
                .optionalInt64(state.bytes)
            ]
        )
    }

    public func listModelStates() throws -> [ModelState] {
        try query("SELECT id, local_path, status, bytes FROM models ORDER BY id ASC") { statement in
            ModelState(
                id: Self.text(statement, 0),
                localPath: Self.optionalText(statement, 1),
                status: ModelInstallStatus(rawValue: Self.text(statement, 2)) ?? .missing,
                bytes: Self.optionalInt64(statement, 3)
            )
        }
    }

    public func saveConsent(_ consent: ConsentRecord) throws -> String {
        try execute(
            """
            INSERT OR REPLACE INTO consent_records (id, audio_source, purpose, created_at)
            VALUES (?, ?, ?, ?)
            """,
            [
                .text(consent.id),
                .text(consent.audioSource),
                .text(consent.purpose),
                .double(consent.createdAt.timeIntervalSince1970)
            ]
        )
        return consent.id
    }

    public func listConsents() throws -> [ConsentRecord] {
        try query("SELECT id, audio_source, purpose, created_at FROM consent_records ORDER BY created_at ASC") { statement in
            ConsentRecord(
                id: Self.text(statement, 0),
                audioSource: Self.text(statement, 1),
                purpose: Self.text(statement, 2),
                createdAt: Date(timeIntervalSince1970: Self.double(statement, 3))
            )
        }
    }

    public func saveVoiceAsset(_ asset: VoiceAsset) throws -> String {
        try execute(
            """
            INSERT OR REPLACE INTO voice_assets
            (id, type, speaker, language, instruct, ref_audio_path, ref_text, clone_prompt_path, consent_id, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [
                .text(asset.id),
                .text(asset.type.rawValue),
                .optionalText(asset.speaker),
                .text(asset.language),
                .text(asset.instruct),
                .optionalText(asset.refAudioPath),
                .optionalText(asset.refText),
                .optionalText(asset.clonePromptPath),
                .optionalText(asset.consentID),
                .double(asset.createdAt.timeIntervalSince1970)
            ]
        )
        return asset.id
    }

    public func listVoiceAssets() throws -> [VoiceAsset] {
        try query(
            """
            SELECT id, type, speaker, language, instruct, ref_audio_path, ref_text, clone_prompt_path, consent_id, created_at
            FROM voice_assets ORDER BY created_at ASC
            """
        ) { statement in
            VoiceAsset(
                id: Self.text(statement, 0),
                type: VoiceKind(rawValue: Self.text(statement, 1)) ?? .customVoice,
                speaker: Self.optionalText(statement, 2),
                language: Self.text(statement, 3),
                instruct: Self.text(statement, 4),
                refAudioPath: Self.optionalText(statement, 5),
                refText: Self.optionalText(statement, 6),
                clonePromptPath: Self.optionalText(statement, 7),
                consentID: Self.optionalText(statement, 8),
                createdAt: Date(timeIntervalSince1970: Self.double(statement, 9))
            )
        }
    }

    public func saveReferenceRecording(_ recording: ReferenceRecording) throws -> String {
        try execute(
            """
            INSERT OR REPLACE INTO reference_recordings
            (id, path, duration, transcript, consent_id, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            [
                .text(recording.id),
                .text(recording.path),
                .double(recording.duration),
                .text(recording.transcript),
                .optionalText(recording.consentID),
                .double(recording.createdAt.timeIntervalSince1970)
            ]
        )
        return recording.id
    }

    public func listReferenceRecordings() throws -> [ReferenceRecording] {
        try query(
            """
            SELECT id, path, duration, transcript, consent_id, created_at
            FROM reference_recordings ORDER BY created_at DESC
            """
        ) { statement in
            ReferenceRecording(
                id: Self.text(statement, 0),
                path: Self.text(statement, 1),
                duration: Self.double(statement, 2),
                transcript: Self.text(statement, 3),
                consentID: Self.optionalText(statement, 4),
                createdAt: Date(timeIntervalSince1970: Self.double(statement, 5))
            )
        }
    }

    public func saveGeneration(_ generation: GenerationRecord) throws {
        try execute(
            """
            INSERT OR REPLACE INTO generations
            (id, mode, model_id, voice_asset_id, text, instruct, audio_path, runtime, status, error, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [
                .text(generation.id),
                .text(generation.mode),
                .text(generation.modelID),
                .optionalText(generation.voiceAssetID),
                .text(generation.text),
                .text(generation.instruct),
                .text(generation.audioPath),
                .text(generation.runtime),
                .text(generation.status.rawValue),
                .optionalText(generation.error),
                .double(generation.createdAt.timeIntervalSince1970)
            ]
        )
    }

    public func listGenerations() throws -> [GenerationRecord] {
        try query(
            """
            SELECT id, mode, model_id, voice_asset_id, text, instruct, audio_path, runtime, status, error, created_at
            FROM generations ORDER BY created_at DESC
            """
        ) { statement in
            GenerationRecord(
                id: Self.text(statement, 0),
                mode: Self.text(statement, 1),
                modelID: Self.text(statement, 2),
                voiceAssetID: Self.optionalText(statement, 3),
                text: Self.text(statement, 4),
                instruct: Self.text(statement, 5),
                audioPath: Self.text(statement, 6),
                runtime: Self.text(statement, 7),
                status: GenerationStatus(rawValue: Self.text(statement, 8)) ?? .failed,
                error: Self.optionalText(statement, 9),
                createdAt: Date(timeIntervalSince1970: Self.double(statement, 10))
            )
        }
    }

    public func saveProject(title: String, rawText: String, defaultVoiceID: String?) throws -> String {
        let project = VoiceProject(title: title, rawText: rawText, defaultVoiceID: defaultVoiceID)
        try execute(
            """
            INSERT INTO projects (id, title, raw_text, default_voice_id, created_at)
            VALUES (?, ?, ?, ?, ?)
            """,
            [
                .text(project.id),
                .text(project.title),
                .text(project.rawText),
                .optionalText(project.defaultVoiceID),
                .double(project.createdAt.timeIntervalSince1970)
            ]
        )
        return project.id
    }

    public func listProjects() throws -> [VoiceProject] {
        try query("SELECT id, title, raw_text, default_voice_id, created_at FROM projects ORDER BY created_at DESC") { statement in
            VoiceProject(
                id: Self.text(statement, 0),
                title: Self.text(statement, 1),
                rawText: Self.text(statement, 2),
                defaultVoiceID: Self.optionalText(statement, 3),
                createdAt: Date(timeIntervalSince1970: Self.double(statement, 4))
            )
        }
    }

    public func rewritePathPrefix(from oldPrefix: String, to newPrefix: String) throws {
        guard oldPrefix != newPrefix else { return }
        let updates = [
            ("voices", "reference_audio_path"),
            ("consent_records", "audio_source"),
            ("voice_assets", "ref_audio_path"),
            ("voice_assets", "clone_prompt_path"),
            ("reference_recordings", "path"),
            ("generations", "audio_path")
        ]
        for update in updates {
            try execute(
                "UPDATE \(update.0) SET \(update.1) = REPLACE(\(update.1), ?, ?) WHERE \(update.1) LIKE ?",
                [
                    .text(oldPrefix),
                    .text(newPrefix),
                    .text("\(oldPrefix)%")
                ]
            )
        }
    }

    public func deleteVoice(id: String, workspaceRoot: String, deleteFiles: Bool = false, fileManager: FileManager = .default) throws {
        let voices = try listVoices().filter { $0.id == id }
        let assets = try listVoiceAssets().filter { $0.id == id }
        var candidatePaths: [String] = []
        for voice in voices {
            candidatePaths.append(contentsOf: [voice.referenceAudioPath].compactMap { $0 })
        }
        for asset in assets {
            candidatePaths.append(contentsOf: [asset.refAudioPath, asset.clonePromptPath].compactMap { $0 })
        }

        try execute("DELETE FROM voice_assets WHERE id = ?", [.text(id)])
        try execute("DELETE FROM voices WHERE id = ?", [.text(id)])

        guard deleteFiles else { return }
        let remainingPaths = Set(
            try listVoices().flatMap { [$0.referenceAudioPath].compactMap { $0 } }
                + listVoiceAssets().flatMap { [$0.refAudioPath, $0.clonePromptPath].compactMap { $0 } }
        )
        for path in Set(candidatePaths) where isPath(path, inside: workspaceRoot) && !remainingPaths.contains(path) {
            if fileManager.fileExists(atPath: path) {
                try? fileManager.removeItem(atPath: path)
            }
        }
    }

    public func renameVoice(id: String, name: String) throws {
        try execute("UPDATE voices SET name = ? WHERE id = ?", [.text(name), .text(id)])
        try execute("UPDATE voice_assets SET speaker = ? WHERE id = ?", [.text(name), .text(id)])
    }

    public func deleteGeneration(id: String, workspaceRoot: String, deleteFile: Bool = false, fileManager: FileManager = .default) throws {
        let generations = try listGenerations().filter { $0.id == id }
        let candidatePaths = generations.map(\.audioPath).filter { !$0.isEmpty }

        try execute("DELETE FROM generations WHERE id = ?", [.text(id)])

        guard deleteFile else { return }
        let remainingPaths = Set(try listGenerations().map(\.audioPath).filter { !$0.isEmpty })
        for path in Set(candidatePaths) where isPath(path, inside: workspaceRoot) && !remainingPaths.contains(path) {
            if fileManager.fileExists(atPath: path) {
                try? fileManager.removeItem(atPath: path)
            }
        }
    }

    private func isPath(_ path: String, inside workspaceRoot: String) -> Bool {
        let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        let standardizedRoot = URL(fileURLWithPath: workspaceRoot, isDirectory: true).standardizedFileURL.path
        return standardizedPath == standardizedRoot || standardizedPath.hasPrefix("\(standardizedRoot)/")
    }

    private func migrate() throws {
        try execute("""
        CREATE TABLE IF NOT EXISTS voices (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            kind TEXT NOT NULL,
            language TEXT NOT NULL,
            speaker TEXT,
            instruct TEXT NOT NULL,
            reference_audio_path TEXT,
            reference_text TEXT,
            consent_id TEXT,
            created_at REAL NOT NULL
        );
        """)
        try execute("""
        CREATE TABLE IF NOT EXISTS models (
            id TEXT PRIMARY KEY,
            local_path TEXT,
            status TEXT NOT NULL,
            bytes INTEGER
        );
        """)
        try execute("""
        CREATE TABLE IF NOT EXISTS consent_records (
            id TEXT PRIMARY KEY,
            audio_source TEXT NOT NULL,
            purpose TEXT NOT NULL,
            created_at REAL NOT NULL
        );
        """)
        try execute("""
        CREATE TABLE IF NOT EXISTS projects (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            raw_text TEXT NOT NULL,
            default_voice_id TEXT,
            created_at REAL NOT NULL
        );
        """)
        try execute("""
        CREATE TABLE IF NOT EXISTS voice_assets (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            speaker TEXT,
            language TEXT NOT NULL,
            instruct TEXT,
            ref_audio_path TEXT,
            ref_text TEXT,
            clone_prompt_path TEXT,
            consent_id TEXT,
            created_at REAL NOT NULL
        );
        """)
        try execute("""
        CREATE TABLE IF NOT EXISTS reference_recordings (
            id TEXT PRIMARY KEY,
            path TEXT NOT NULL,
            duration REAL NOT NULL,
            transcript TEXT,
            consent_id TEXT,
            created_at REAL NOT NULL
        );
        """)
        try execute("""
        CREATE TABLE IF NOT EXISTS generations (
            id TEXT PRIMARY KEY,
            mode TEXT NOT NULL,
            model_id TEXT NOT NULL,
            voice_asset_id TEXT,
            text TEXT NOT NULL,
            instruct TEXT,
            audio_path TEXT NOT NULL,
            runtime TEXT NOT NULL,
            status TEXT NOT NULL,
            error TEXT,
            created_at REAL NOT NULL
        );
        """)
    }

    private enum SQLiteValue {
        case text(String)
        case optionalText(String?)
        case double(Double)
        case optionalInt64(Int64?)
    }

    private func execute(_ sql: String, _ values: [SQLiteValue] = []) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw AppDatabaseError.prepareFailed(errorMessage)
        }
        defer { sqlite3_finalize(statement) }
        try bind(values, to: statement)
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw AppDatabaseError.executeFailed(errorMessage)
        }
    }

    private func query<T>(_ sql: String, map: (OpaquePointer?) throws -> T) throws -> [T] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw AppDatabaseError.prepareFailed(errorMessage)
        }
        defer { sqlite3_finalize(statement) }

        var result: [T] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            result.append(try map(statement))
        }
        return result
    }

    private func bind(_ values: [SQLiteValue], to statement: OpaquePointer?) throws {
        for (offset, value) in values.enumerated() {
            let index = Int32(offset + 1)
            let code: Int32
            switch value {
            case .text(let text):
                code = sqlite3_bind_text(statement, index, text, -1, SQLITE_TRANSIENT)
            case .optionalText(let text):
                if let text {
                    code = sqlite3_bind_text(statement, index, text, -1, SQLITE_TRANSIENT)
                } else {
                    code = sqlite3_bind_null(statement, index)
                }
            case .double(let double):
                code = sqlite3_bind_double(statement, index, double)
            case .optionalInt64(let int):
                if let int {
                    code = sqlite3_bind_int64(statement, index, int)
                } else {
                    code = sqlite3_bind_null(statement, index)
                }
            }
            guard code == SQLITE_OK else {
                throw AppDatabaseError.executeFailed(errorMessage)
            }
        }
    }

    private var errorMessage: String {
        sqlite3_errmsg(db).map(String.init(cString:)) ?? "SQLite error"
    }

    private static func text(_ statement: OpaquePointer?, _ column: Int32) -> String {
        sqlite3_column_text(statement, column).map { String(cString: $0) } ?? ""
    }

    private static func optionalText(_ statement: OpaquePointer?, _ column: Int32) -> String? {
        guard sqlite3_column_type(statement, column) != SQLITE_NULL else { return nil }
        return text(statement, column)
    }

    private static func double(_ statement: OpaquePointer?, _ column: Int32) -> Double {
        sqlite3_column_double(statement, column)
    }

    private static func optionalInt64(_ statement: OpaquePointer?, _ column: Int32) -> Int64? {
        guard sqlite3_column_type(statement, column) != SQLITE_NULL else { return nil }
        return sqlite3_column_int64(statement, column)
    }
}

extension AppDatabase: @unchecked Sendable {}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
