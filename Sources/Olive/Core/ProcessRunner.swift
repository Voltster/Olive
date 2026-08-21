import Foundation

public struct ProcessResult: Sendable {
    public let exitCode: Int32
    public let stdout: String
    public let stderr: String
    
    public var isSuccess: Bool {
        return exitCode == 0
    }
}

public actor ProcessRunner {
    public static let shared = ProcessRunner()
    
    public init() {}
    
    @discardableResult
    public func run(
        command: String,
        arguments: [String] = [],
        currentDirectory: String? = nil,
        environment: [String: String]? = nil
    ) async throws -> ProcessResult {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments
        
        if let currentDirectory = currentDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: currentDirectory)
        }
        
        if let environment = environment {
            var env = ProcessInfo.processInfo.environment
            for (key, value) in environment {
                env[key] = value
            }
            process.environment = env
        }
        
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try process.run()
                
                DispatchQueue.global(qos: .userInitiated).async {
                    let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                    let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                    
                    process.waitUntilExit()
                    
                    let stdout = String(data: stdoutData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let stderr = String(data: stderrData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    
                    let result = ProcessResult(
                        exitCode: process.terminationStatus,
                        stdout: stdout,
                        stderr: stderr
                    )
                    
                    continuation.resume(returning: result)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    @discardableResult
    public func runShellScript(_ script: String) async throws -> ProcessResult {
        return try await run(
            command: "/bin/zsh",
            arguments: ["-c", script]
        )
    }
}
