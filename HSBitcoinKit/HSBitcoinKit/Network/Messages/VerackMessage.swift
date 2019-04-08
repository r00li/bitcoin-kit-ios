import Foundation

/// The verack message is sent in reply to version.
/// This message consists of only a message header with the command string "verack".
struct VerackMessage: IMessage {
    let command: String = "verack"
}
