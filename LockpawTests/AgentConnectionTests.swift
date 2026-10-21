import XCTest
@testable import Lockpaw

final class AgentConnectionTests: XCTestCase {
    func testEveryAgentHasAConfigFile() {
        for agent in AgentConnection.agents {
            XCTAssertNotNil(AgentConnection.configURL(for: agent, environment: ["HOME": "/Users/test"]), agent)
        }
        XCTAssertNil(AgentConnection.configURL(for: "nope", environment: ["HOME": "/Users/test"]))
    }

    func testConfigPathsFollowTheAgentsOwnVariables() {
        let env = ["HOME": "/Users/test", "CLAUDE_CONFIG_DIR": "/Users/test/.claude-work", "CODEX_HOME": "/opt/codex"]
        XCTAssertEqual(AgentConnection.configURL(for: "claude", environment: env)?.path, "/Users/test/.claude-work/settings.json")
        XCTAssertEqual(AgentConnection.configURL(for: "codex", environment: env)?.path, "/opt/codex/config.toml")
        XCTAssertEqual(AgentConnection.configURL(for: "gemini", environment: env)?.path, "/Users/test/.gemini/settings.json")
        XCTAssertEqual(AgentConnection.configURL(for: "copilot", environment: ["HOME": "/Users/test"])?.path, "/Users/test/.copilot/hooks/lockpaw.json")
    }

    func testAConfigIsConnectedWhenALineRunsALockpawPing() {
        let claude = #"{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"\"$HOME/.local/bin/lockpaw\" ping --agent claude"}]}]}}"#
        XCTAssertTrue(AgentConnection.isConnected(configContents: claude))
        XCTAssertTrue(AgentConnection.isConnected(configContents: #"notify = ["/Users/test/.local/bin/lockpaw", "ping", "--agent", "codex"]"#))
        XCTAssertTrue(AgentConnection.isConnected(configContents: "notifications: true\nnotifications-command: /Users/test/.local/bin/lockpaw ping --done\n"))
    }

    func testOtherHooksAreNotAConnection() {
        XCTAssertFalse(AgentConnection.isConnected(configContents: #"{"hooks":{"Stop":[{"hooks":[{"command":"say done"}]}]}}"#))
        // "lockpaw" and "ping" on different lines are not one command.
        XCTAssertFalse(AgentConnection.isConnected(configContents: "# installed lockpaw once\nhost = ping.example.com\n"))
        XCTAssertFalse(AgentConnection.isConnected(configContents: ""))
    }
}
