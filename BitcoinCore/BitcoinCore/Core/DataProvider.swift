import Foundation
import HSHDWalletKit
import RxSwift
import BigInt
import HSCryptoKit

class DataProvider {
    private let disposeBag = DisposeBag()

    private let storage: IStorage
    private let unspentOutputProvider: IUnspentOutputProvider

    private let balanceUpdateSubject = PublishSubject<Void>()

    public var balance: Int = 0 {
        didSet {
            if !(oldValue == balance) {
                delegate?.balanceUpdated(balance: balance)
            }
        }
    }
    public var lastBlockInfo: BlockInfo? = nil

    weak var delegate: IDataProviderDelegate?

    init(storage: IStorage, unspentOutputProvider: IUnspentOutputProvider, throttleTime: Double = 0.5) {
        self.storage = storage
        self.unspentOutputProvider = unspentOutputProvider
        self.balance = unspentOutputProvider.balance
        self.lastBlockInfo = storage.lastBlock.map { blockInfo(fromBlock: $0) }

        balanceUpdateSubject.throttle(throttleTime, scheduler: ConcurrentDispatchQueueScheduler(qos: .background)).subscribe(onNext: {
            self.balance = unspentOutputProvider.balance
        }).disposed(by: disposeBag)
    }

    private func transactionInfo(fromTransaction transactionForInfo: FullTransactionForInfo) -> TransactionInfo {
        var totalMineInput: Int = 0
        var totalMineOutput: Int = 0
        var fromAddresses = [TransactionAddressInfo]()
        var toAddresses = [TransactionAddressInfo]()

        for inputWithPreviousOutput in transactionForInfo.inputsWithPreviousOutputs {
            var mine = false

            if let previousOutput = inputWithPreviousOutput.previousOutput {
                if previousOutput.publicKeyPath != nil {
                    totalMineInput += previousOutput.value
                    mine = true
                }
            }

            if let address = inputWithPreviousOutput.input.address {
                fromAddresses.append(TransactionAddressInfo(address: address, mine: mine))
            }
        }

        for output in transactionForInfo.outputs {
            var mine = false

            if output.publicKeyPath != nil {
                totalMineOutput += output.value
                mine = true
            }

            if let address = output.address {
                toAddresses.append(TransactionAddressInfo(address: address, mine: mine))
            }
        }

        let amount = totalMineOutput - totalMineInput

        return TransactionInfo(
                transactionHash: transactionForInfo.transactionWithBlock.transaction.dataHash.reversedHex,
                from: fromAddresses,
                to: toAddresses,
                amount: amount,
                blockHeight: transactionForInfo.transactionWithBlock.blockHeight,
                timestamp: transactionForInfo.transactionWithBlock.transaction.timestamp
        )
    }

    private func blockInfo(fromBlock block: Block) -> BlockInfo {
        return BlockInfo(
                headerHash: block.headerHash.reversedHex,
                height: block.height,
                timestamp: block.timestamp
        )
    }

    var feeRate: FeeRate {
        return storage.feeRate ?? FeeRate.defaultFeeRate
    }

}

extension DataProvider: IBlockchainDataListener {

    func onUpdate(updated: [Transaction], inserted: [Transaction], inBlock block: Block?) {
        var blocks = [Block]()

        if let block = block {
            blocks.append(block)
        }

        delegate?.transactionsUpdated(
                inserted: storage.fullInfo(forTransactions: inserted.map { TransactionWithBlock(transaction: $0, blockHeight: block?.height) }).map { transactionInfo(fromTransaction: $0) },
                updated: storage.fullInfo(forTransactions: updated.map { TransactionWithBlock(transaction: $0, blockHeight: block?.height) }).map { transactionInfo(fromTransaction: $0) }
        )

        balanceUpdateSubject.onNext(())
    }

    func onDelete(transactionHashes: [String]) {
        delegate?.transactionsDeleted(hashes: transactionHashes)

        balanceUpdateSubject.onNext(())
    }

    func onInsert(block: Block) {
        if block.height > (lastBlockInfo?.height ?? 0) {
            let lastBlockInfo = blockInfo(fromBlock: block)
            self.lastBlockInfo = lastBlockInfo
            delegate?.lastBlockInfoUpdated(lastBlockInfo: lastBlockInfo)

            balanceUpdateSubject.onNext(())
        }
    }

}

extension DataProvider: IDataProvider {

    func transactions(fromHash: String?, limit: Int?) -> Single<[TransactionInfo]> {
        return Single.create { observer in
            var fromTimestamp: Int? = nil
            var fromOrder: Int? = nil

            if let fromHash = fromHash, let fromHashData = Data(hex: fromHash), let fromTransaction = self.storage.transaction(byHash: Data(fromHashData.reversed())) {
                fromTimestamp = fromTransaction.timestamp
                fromOrder = fromTransaction.order
            }

            let transactions = self.storage.fullTransactionsInfo(fromTimestamp: fromTimestamp, fromOrder: fromOrder, limit: limit)

            observer(.success(transactions.map() { self.transactionInfo(fromTransaction: $0) }))
            return Disposables.create()
        }
    }

    var debugInfo: String {
        var lines = [String]()

//        let transactions = storage.transactions(sortedBy: Transaction.Columns.timestamp, secondSortedBy: Transaction.Columns.order, ascending: false)
        let pubKeys = storage.publicKeys()

        for pubKey in pubKeys {

//            lines.append("\(pubKey.account) --- \(pubKey.index) --- \(pubKey.external) --- hash: \(pubKey.keyHash.hex) --- p2wkph(SH) hash: \(pubKey.scriptHashForP2WPKH.hex)")
            lines.append("acc: \(pubKey.account) - inx: \(pubKey.index) - ext: \(pubKey.external) : \((try! Base58AddressConverter(addressVersion: 0x6f, addressScriptVersion: 0xc4).convert(keyHash: pubKey.keyHash, type: .p2pkh)).stringValue)")
        }
        lines.append("PUBLIC KEYS COUNT: \(pubKeys.count)")
//        lines.append("TRANSACTIONS COUNT: \(transactions.count)")
//        lines.append("BLOCK COUNT: \(storage.blocksCount)")
//        if let block = storage.firstBlock {
//            lines.append("First Block: \(block.height) --- \(block.headerHashReversedHex)")
//        }
//        if let block = storage.lastBlock {
//            lines.append("Last Block: \(block.height) --- \(block.headerHashReversedHex)")
//        }
//
        return lines.joined(separator: "\n")
    }

}
