import Foundation
import HSCryptoKit
import GRDB

public class PublicKey: Record {

    public enum InitError: Error {
        case invalid
        case wrongNetwork
    }

    public let path: String
    public let account: Int
    public let index: Int
    public let external: Bool
    public let raw: Data
    public let keyHash: Data
    public let scriptHashForP2WPKH: Data
    public let keyHashHex: String

    init(withAccount account: Int, index: Int, external: Bool, hdPublicKeyData data: Data) {
        self.account = account
        self.index = index
        self.external = external
        path = "\(account)/\(index)/\(external ? 1 : 0)"
        raw = data
        keyHash = CryptoKit.sha256ripemd160(data)

        scriptHashForP2WPKH = CryptoKit.sha256ripemd160(OpCode.scriptWPKH(keyHash))
        keyHashHex = keyHash.hex

        super.init()
    }

    override open class var databaseTableName: String {
        return "publicKeys"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
        case path
        case account
        case index
        case external
        case raw
        case keyHash
        case scriptHashForP2WPKH
        case keyHashHex
    }

    required init(row: Row) {
        path = row[Columns.path]
        account = row[Columns.account]
        index = row[Columns.index]
        external = row[Columns.external]
        raw = row[Columns.raw]
        keyHash = row[Columns.keyHash]
        scriptHashForP2WPKH = row[Columns.scriptHashForP2WPKH]
        keyHashHex = row[Columns.keyHashHex]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.path] = path
        container[Columns.account] = account
        container[Columns.index] = index
        container[Columns.external] = external
        container[Columns.raw] = raw
        container[Columns.keyHash] = keyHash
        container[Columns.scriptHashForP2WPKH] = scriptHashForP2WPKH
        container[Columns.keyHashHex] = keyHashHex
    }

}
