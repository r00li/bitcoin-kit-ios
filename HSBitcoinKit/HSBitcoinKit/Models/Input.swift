import Foundation
import GRDB

public class Input: Record {

    public var previousOutputTxReversedHex: String
    public var previousOutputIndex: Int
    public var signatureScript: Data
    public var sequence: Int
    public var transactionHashReversedHex = ""
    public var keyHash: Data? = nil
    public var address: String? = nil
    public var witnessData = [Data]()

    init(withPreviousOutputTxReversedHex previousOutputTxReversedHex: String, previousOutputIndex: Int, script: Data, sequence: Int) {
        self.previousOutputTxReversedHex = previousOutputTxReversedHex
        self.previousOutputIndex = previousOutputIndex
        self.signatureScript = script
        self.sequence = sequence

        super.init()
    }


    override open class var databaseTableName: String {
        return "inputs"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
        case previousOutputTxReversedHex
        case previousOutputIndex
        case signatureScript
        case sequence
        case transactionHashReversedHex
        case keyHash
        case address
        case witnessData
    }

    required init(row: Row) {
        previousOutputTxReversedHex = row[Columns.previousOutputTxReversedHex]
        previousOutputIndex = row[Columns.previousOutputIndex]
        signatureScript = row[Columns.signatureScript]
        sequence = row[Columns.sequence]
        transactionHashReversedHex = row[Columns.transactionHashReversedHex]
        keyHash = row[Columns.keyHash]
        address = row[Columns.address]
        witnessData = row[Columns.witnessData]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.previousOutputTxReversedHex] = previousOutputTxReversedHex
        container[Columns.previousOutputIndex] = previousOutputIndex
        container[Columns.signatureScript] = signatureScript
        container[Columns.sequence] = sequence
        container[Columns.transactionHashReversedHex] = transactionHashReversedHex
        container[Columns.keyHash] = keyHash
        container[Columns.address] = address
        container[Columns.witnessData] = witnessData
    }

}

enum SerializationError: Error {
    case noPreviousOutput
    case noPreviousTransaction
}
