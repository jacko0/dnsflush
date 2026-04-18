import ArgumentParser
import Foundation

@main
struct DNSFlush: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dnsflush",
        abstract: "Flush macOS DNS cache",
        discussion: """
            A simple utility to flush the macOS DNS resolver cache.
            
            It clears the DNS cache using dscacheutil and restarts the mDNSResponder service.
            Uses AppleScript so you get the normal macOS password dialog.
            
            Author: S.Jackson 2026
            """,
        // -v / --version now shows the version + extra info you wanted
        version: """
            dnsflush 1.0.0
            Flush macOS DNS cache
            
            Author: S.Jackson 2026
            """
    )

    mutating func run() throws {
        print("🔄 Flushing DNS cache...")

        let appleScript = """
        do shell script "dscacheutil -flushcache; killall -HUP mDNSResponder" with administrator privileges
        """

        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", appleScript]

        do {
            try task.run()
            task.waitUntilExit()

            if task.terminationStatus == 0 {
                print("✅ DNS cache flushed successfully.")
            } else {
                print("⚠️  Command finished but reported errors.")
            }
        } catch {
            print("❌ Failed to flush DNS cache:\n\(error.localizedDescription)")
            throw ExitCode.failure
        }
    }
}
