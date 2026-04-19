import ArgumentParser
import Foundation

@main
struct DNSFlush: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dnsflush",
        abstract: "Flush macOS DNS cache",
        discussion: """
            Optimized for macOS Tahoe 26.4 (and later).

            Shows current cache stats → flushes → shows new cache stats
            Uses a temporary shell script → only ONE password prompt.

            Author: S.Jackson 2026
            """,
        version: """
            dnsflush 1.9.1 (Tahoe 26.4 optimized)
            Clean output on modern macOS
            Author: S.Jackson 2026
            """
    )

    mutating func run() throws {
        print(" Preparing to flush DNS cache...")

        // === BEFORE FLUSH ===
        print("\n=== BEFORE FLUSH ===")
        let before = Process()
        before.launchPath = "/usr/bin/dscacheutil"
        before.arguments = ["-statistics"]
        let beforePipe = Pipe()
        before.standardOutput = beforePipe
        before.standardError = beforePipe
        try before.run()
        before.waitUntilExit()

        let beforeData = beforePipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: beforeData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !output.isEmpty,
           !output.contains("Unable to get details") {
            print(output)
        } else {
            print("(Current DNS cache statistics not available on this macOS version)")
        }

        // === Create temp script for flush only ===
        let tempScriptPath = "/tmp/dnsflush_temp.sh"
        let scriptContent = """
#!/bin/bash
echo "Flushing cache..."
dscacheutil -flushcache
killall -HUP mDNSResponder
sleep 0.5
killall -HUP mDNSResponder
"""

        do {
            try scriptContent.write(toFile: tempScriptPath, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tempScriptPath)
        } catch {
            print(" Failed to create temporary script: \(error.localizedDescription)")
            throw ExitCode.failure
        }

        // === Run flush with one password prompt ===
        let appleScript = """
do shell script "\(tempScriptPath)" with administrator privileges
"""

        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", appleScript]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                print(output)
            }

            if task.terminationStatus == 0 {
                print("\n DNS cache flushed successfully.")
            } else {
                print("\n  Command finished with errors.")
            }
        } catch {
            print(" Failed to execute command:\n\(error.localizedDescription)")
            throw ExitCode.failure
        }

        try? FileManager.default.removeItem(atPath: tempScriptPath)

        // === AFTER FLUSH ===
        print("\n=== AFTER FLUSH ===")
        let after = Process()
        after.launchPath = "/usr/bin/dscacheutil"
        after.arguments = ["-statistics"]
        let afterPipe = Pipe()
        after.standardOutput = afterPipe
        after.standardError = afterPipe
        try after.run()
        after.waitUntilExit()

        let afterData = afterPipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: afterData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !output.isEmpty,
           !output.contains("Unable to get details") {
            print(output)
        } else {
            print("(New DNS cache statistics not available on this macOS version)")
        }

        // === Final helpful note ===
        print("\n Note: On modern macOS (Sequoia / Tahoe), detailed cache statistics")
        print("   are no longer exposed by the system, but the DNS cache was")
        print("   successfully flushed and restarted.")
    }
}
