import Foundation

/// Whether an agent already has Lockpaw's ping hook, read from the same config file
/// `lockpaw install-hook` writes. Best effort and read-only: Settings uses it to mark an
/// agent as connected. It follows `$HOME` and the agents' own directory variables when
/// they're set, but a GUI app usually launches without them, so a custom
/// `CLAUDE_CONFIG_DIR` profile can read as not connected.
enum AgentConnection {
    static let agents = ["claude", "codex", "gemini", "cursor", "copilot", "aider"]

    static func displayName(_ agent: String) -> String {
        switch agent {
        case "claude": return "Claude Code"
        case "codex": return "Codex"
        case "gemini": return "Gemini"
        case "cursor": return "Cursor"
        case "copilot": return "Copilot"
        case "aider": return "Aider"
        default: return agent
        }
    }

    /// The file holding the agent's hook, relative to the environment's directories.
    static func configURL(for agent: String, environment: [String: String] = ProcessInfo.processInfo.environment) -> URL? {
        let home = URL(fileURLWithPath: environment["HOME"].flatMap { $0.isEmpty ? nil : $0 } ?? NSHomeDirectory(), isDirectory: true)
        func dir(_ variable: String, default path: String) -> URL {
            if let value = environment[variable], !value.isEmpty {
                return URL(fileURLWithPath: (value as NSString).expandingTildeInPath, isDirectory: true)
            }
            return home.appendingPathComponent(path, isDirectory: true)
        }
        switch agent {
        case "claude": return dir("CLAUDE_CONFIG_DIR", default: ".claude").appendingPathComponent("settings.json")
        case "codex": return dir("CODEX_HOME", default: ".codex").appendingPathComponent("config.toml")
        case "gemini": return home.appendingPathComponent(".gemini/settings.json")
        case "cursor": return home.appendingPathComponent(".cursor/hooks.json")
        case "copilot": return dir("COPILOT_HOME", default: ".copilot").appendingPathComponent("hooks/lockpaw.json")
        case "aider": return home.appendingPathComponent(".aider.conf.yml")
        default: return nil
        }
    }

    /// A config holds Lockpaw's hook when any line of it runs a lockpaw ping.
    static func isConnected(configContents: String) -> Bool {
        configContents.split(whereSeparator: \.isNewline).contains { AgentHookConfig.isLockpawPingCommand(String($0)) }
    }

    static func isConnected(_ agent: String) -> Bool {
        guard let url = configURL(for: agent), let contents = try? String(contentsOf: url, encoding: .utf8) else { return false }
        return isConnected(configContents: contents)
    }
}
