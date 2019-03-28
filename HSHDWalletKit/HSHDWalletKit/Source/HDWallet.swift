import Foundation

public class HDWallet {
    private var publicKey: Data?
    private var seed: Data?
    private var keychain: HDKeychain?

    private var purpose: UInt32
    private var coinType: UInt32
    public var gapLimit: Int
    private(set) var isColdWallet: Bool = false

    public init(seed: Data, coinType: UInt32, xPrivKey: UInt32, xPubKey: UInt32, gapLimit: Int = 5) {
        self.seed = seed
        self.gapLimit = gapLimit

        keychain = HDKeychain(seed: seed, xPrivKey: xPrivKey, xPubKey: xPubKey)
        purpose = 44
        self.coinType = coinType
    }
    
    public init(publicKey: Data, gapLimit: Int = 5) {
        self.gapLimit = gapLimit
        self.isColdWallet = true
        
        // When initializing a cold wallet this data is read from public key, so these values here don't matter.
        self.purpose = 44
        self.coinType = 0
    }

    public func privateKey(account: Int, index: Int, chain: Chain) throws -> HDPrivateKey {
        return try privateKey(path: "m/\(purpose)'/\(coinType)'/\(account)'/\(chain.rawValue)/\(index)")
    }

    public func privateKey(path: String) throws -> HDPrivateKey {
        guard let keychain = keychain else {
            throw NSError(domain: "RNS HD Wallet", code: 0, userInfo: nil)
        }
        
        let privateKey = try keychain.derivedKey(path: path)
        return privateKey
    }
    
    public func publicKey(account: Int, index: Int, chain: Chain) throws -> HDPublicKey {
        return try HDPublicKey(
                            raw: Data(bytes: [0x03, 0x59, 0x5d, 0x88, 0x0c, 0xfe, 0xb1, 0x11, 0xc4, 0xd8, 0x46, 0x83, 0xc7, 0xd7, 0x2e, 0x69, 0x2a, 0x6f, 0x58, 0x3c, 0xcf, 0x24, 0xc4, 0x11, 0x96, 0x40, 0x77, 0x47, 0x27, 0x20, 0x12, 0xa8, 0xd7]),
                           chainCode: Data(bytes: [0x22, 0x41, 0x9c, 0x4e, 0xf5, 0x63, 0x42, 0x02, 0x92, 0x16, 0x51, 0xe2, 0x59, 0xc4, 0xab, 0xf8, 0x93, 0x0e, 0x32, 0x0e, 0x6d, 0x3d, 0xa7, 0xf5, 0x29, 0x98, 0xca, 0x09, 0x25, 0xdd, 0x4e, 0x2b]),
                           xPubKey: 0x043587cf,
                           depth: 0x03,
                           fingerprint: 0xcdfed67d,
                           childIndex: 0x80000000).derived(at: UInt32(account)).derived(at: UInt32(index))
    }

    public enum Chain : Int {
        case external
        case `internal`
    }
    
    /*func derivedKey(path: String) throws -> HDPublicKey {
        var key = HDPublicKey(
            raw: Data(bytes: [0x03, 0x59, 0x5d, 0x88, 0x0c, 0xfe, 0xb1, 0x11, 0xc4, 0xd8, 0x46, 0x83, 0xc7, 0xd7, 0x2e, 0x69, 0x2a, 0x6f, 0x58, 0x3c, 0xcf, 0x24, 0xc4, 0x11, 0x96, 0x40, 0x77, 0x47, 0x27, 0x20, 0x12, 0xa8, 0xd7]),
            chainCode: Data(bytes: [0x22, 0x41, 0x9c, 0x4e, 0xf5, 0x63, 0x42, 0x02, 0x92, 0x16, 0x51, 0xe2, 0x59, 0xc4, 0xab, 0xf8, 0x93, 0x0e, 0x32, 0x0e, 0x6d, 0x3d, 0xa7, 0xf5, 0x29, 0x98, 0xca, 0x09, 0x25, 0xdd, 0x4e, 0x2b]),
            xPubKey: 0x043587cf,
            depth: 0x03,
            fingerprint: 0xcdfed67d,
            childIndex: 0x80000000)
        
        var path = path
        if path == "m" || path == "/" || path == "" {
            return key
        }
        if path.contains("m/") {
            path = String(path.dropFirst(2))
        }
        for chunk in path.split(separator: "/") {
            var hardened = false
            var indexText = chunk
            if chunk.contains("'") {
                hardened = true
                indexText = indexText.dropLast()
            }
            guard let index = UInt32(indexText) else {
                fatalError("invalid path")
            }
            key = try key.derived(at: index)
        }
        return key
    }*/

}
