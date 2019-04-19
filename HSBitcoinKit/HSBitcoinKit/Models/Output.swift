import Foundation
import GRDB

public enum ScriptType: Int, DatabaseValueConvertible {
    case unknown, p2pkh, p2pk, p2multi, p2sh, p2wsh, p2wpkh, p2wpkhSh

    var size: Int {
        switch self {
            case .p2pk: return 35
            case .p2pkh: return 25
            case .p2sh: return 23
            case .p2wsh: return 34
            case .p2wpkh: return 22
            case .p2wpkhSh: return 23
            default: return 0
        }
    }

    var keyLength: UInt8 {
        switch self {
            case .p2pk: return 0x21
            case .p2pkh: return 0x14
            case .p2sh: return 0x14
            case .p2wsh: return 0x20
            case .p2wpkh: return 0x14
            case .p2wpkhSh: return 0x14
            default: return 0
        }
    }

    var addressType: AddressType {
        switch self {
            case .p2sh, .p2wsh: return .scriptHash
            default: return .pubKeyHash
        }
    }

    var witness: Bool {
        return self == .p2wpkh || self == .p2wpkhSh || self == .p2wsh
    }

}

public class Output: Record {

    public var value: Int
    public var lockingScript: Data
    public var index: Int
    public var transactionHashReversedHex: String = ""
    public var publicKeyPath: String? = nil
    public var scriptType: ScriptType = .unknown
    public var keyHash: Data? = nil
    public var address: String? = nil

    init(withValue value: Int, index: Int, lockingScript script: Data, type: ScriptType = .unknown, address: String? = nil, keyHash: Data? = nil, publicKey: PublicKey? = nil) {
        self.value = value
        self.lockingScript = script
        self.index = index
        self.scriptType = type
        self.address = address
        self.keyHash = keyHash
        self.publicKeyPath = publicKey?.path

        super.init()
    }

    override open class var databaseTableName: String {
        return "outputs"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
        case value
        case lockingScript
        case index
        case transactionHashReversedHex
        case publicKeyPath
        case scriptType
        case keyHash
        case address
    }

    required init(row: Row) {
        value = row[Columns.value]
        lockingScript = row[Columns.lockingScript]
        index = row[Columns.index]
        transactionHashReversedHex = row[Columns.transactionHashReversedHex]
        publicKeyPath = row[Columns.publicKeyPath]
        scriptType = row[Columns.scriptType]
        keyHash = row[Columns.keyHash]
        address = row[Columns.address]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.value] = value
        container[Columns.lockingScript] = lockingScript
        container[Columns.index] = index
        container[Columns.transactionHashReversedHex] = transactionHashReversedHex
        container[Columns.publicKeyPath] = publicKeyPath
        container[Columns.scriptType] = scriptType
        container[Columns.keyHash] = keyHash
        container[Columns.address] = address
    }

}
