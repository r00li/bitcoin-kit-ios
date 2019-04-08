import Foundation
import HSCryptoKit

/// The ping message is sent primarily to confirm that the TCP/IP connection is still valid.
/// An error in transmission is presumed to be a closed connection and the address is removed as a current peer.
struct PingMessage: IMessage {
    let command: String = "ping"
    /// random nonce
    let nonce: UInt64
}
