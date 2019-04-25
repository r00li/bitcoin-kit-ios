import Foundation
import HSHDWalletKit
import BigInt
import HSCryptoKit
import RxSwift

public class BitcoinCore {
    static let heightInterval = 2016                                    // Default block count in difficulty change circle ( Bitcoin )
    static let targetSpacing = 10 * 60                                  // Time to mining one block ( 10 min. Bitcoin )
    static let maxTargetBits = 0x1d00ffff                               // Initially and max. target difficulty for blocks


    private let storage: IStorage
    private var dataProvider: IDataProvider & IBlockchainDataListener
    private let addressManager: IAddressManager
    private let addressConverter: AddressConverterChain
    private let kitStateProvider: IKitStateProvider & ISyncStateListener
    private let transactionBuilder: ITransactionBuilder
    private let transactionCreator: ITransactionCreator
    private let paymentAddressParser: IPaymentAddressParser

    private let networkMessageSerializer: NetworkMessageSerializer
    private let networkMessageParser: NetworkMessageParser

    private let syncManager: SyncManager

    // START: Extending

    var peerGroup: IPeerGroup
    var transactionSyncer: ITransactionSyncer

    let blockValidatorChain = BlockValidatorChain(proofOfWorkValidator: ProofOfWorkValidator(difficultyEncoder: DifficultyEncoder()))
    let inventoryItemsHandlerChain = InventoryItemsHandlerChain()
    let peerTaskHandlerChain = PeerTaskHandlerChain()

    func add(blockValidator: IBlockValidator) {
        blockValidatorChain.add(blockValidator: blockValidator)
    }

    func add(inventoryItemsHandler: IInventoryItemsHandler) {
        inventoryItemsHandlerChain.add(handler: inventoryItemsHandler)
    }

    func add(peerTaskHandler: IPeerTaskHandler) {
        peerTaskHandlerChain.add(handler: peerTaskHandler)
    }

    @discardableResult func add(messageParser: IMessageParser) -> Self {
        networkMessageParser.add(parser: messageParser)
        return self
    }

    @discardableResult func add(messageSerializer: IMessageSerializer) -> Self {
        networkMessageSerializer.add(serializer: messageSerializer)
        return self
    }

    func add(peerGroupListener: IPeerGroupListener) {
        peerGroup.add(peerGroupListener: peerGroupListener)
    }

    func prepend(addressConverter: IAddressConverter) {
        self.addressConverter.prepend(addressConverter: addressConverter)
    }

    // END: Extending

    public var delegateQueue = DispatchQueue(label: "bitcoin_delegate_queue")
    var delegates = [BitcoinCoreDelegate]()

    func add(delegate: BitcoinCoreDelegate) {
        delegates.append(delegate)
    }


    init(storage: IStorage, dataProvider: IDataProvider & IBlockchainDataListener,
                peerGroup: IPeerGroup, transactionSyncer: ITransactionSyncer,
                addressManager: IAddressManager, addressConverter: AddressConverterChain, kitStateProvider: IKitStateProvider & ISyncStateListener,
                transactionBuilder: ITransactionBuilder, transactionCreator: ITransactionCreator, paymentAddressParser: IPaymentAddressParser,
                networkMessageParser: NetworkMessageParser, networkMessageSerializer: NetworkMessageSerializer,
                syncManager: SyncManager) {
        self.storage = storage
        self.dataProvider = dataProvider
        self.peerGroup = peerGroup
        self.transactionSyncer = transactionSyncer
        self.addressManager = addressManager
        self.addressConverter = addressConverter
        self.kitStateProvider = kitStateProvider
        self.transactionBuilder = transactionBuilder
        self.transactionCreator = transactionCreator
        self.paymentAddressParser = paymentAddressParser

        self.networkMessageParser = networkMessageParser
        self.networkMessageSerializer = networkMessageSerializer

        self.syncManager = syncManager
    }

}

extension BitcoinCore {

    public func start() throws {
        syncManager.start()
    }

    public func clear() throws {
        syncManager.stop()
        try storage.clear()
    }

}

extension BitcoinCore {

    public var lastBlockInfo: BlockInfo? {
        return dataProvider.lastBlockInfo
    }

    public var balance: Int {
        return dataProvider.balance
    }

    public var syncState: BitcoinCore.KitState {
        return kitStateProvider.syncState
    }

    public func transactions(fromHash: String? = nil, limit: Int? = nil) -> Single<[TransactionInfo]> {
        return dataProvider.transactions(fromHash: fromHash, limit: limit)
    }

    public func send(to address: String, value: Int, feePriority: FeePriority = .medium) throws {
        try transactionCreator.create(to: address, value: value, feeRate: getFeeRate(priority: feePriority), senderPay: true)
    }
    
    // KAMINO MOD:
    //--------------------------------------------------------------------------------------------------------------------------------------------------------
    
    public typealias NonSignedTransaction = (transaction: FullTransaction, inputHashes: [Data], inputPublicKeys: [PublicKey])
    
    public func transaction(fromHash: String?) -> FullTransaction? {
        guard let fromHash = fromHash else {
            return nil
        }
        
        if let fromTransaction = self.storage.transaction(byHashHex: fromHash) {
            let inputs = self.storage.inputs(ofTransaction: fromTransaction)
            let outputs = self.storage.outputs(ofTransaction: fromTransaction)
            
            return FullTransaction(header: fromTransaction, inputs: inputs, outputs: outputs)
        }
        
        return nil
    }
    
    public func createColdWalletTransaction(to address: String, value: Int, feePriority: FeePriority = .medium) throws -> NonSignedTransaction {
        // Modified send function that normally calls many methods. This removes the unecessary middle steps
        
        try peerGroup.checkPeersSynced()
        
        //let transaction = try transactionBuilder.buildTransaction(value: value, feeRate: transactionFee.medium, senderPay: true, toAddress: address)
        let transaction = try transactionBuilder.buildColdTransaction(value: value, feeRate: getFeeRate(priority: feePriority), senderPay: true, toAddress: address)
        print(transaction)
        //return transaction
        //try transactionProcessor.processCreated(transaction: transaction)
        //try peerGroup.sendPendingTransactions()
        
        return transaction
    }
    
    // END KAMINO MOD:
    //--------------------------------------------------------------------------------------------------------------------------------------------------------
    
    public func sendColdWalletTransaction() {
        
    }

    public func validate(address: String) throws {
        _ = try addressConverter.convert(address: address)
    }

    public func parse(paymentAddress: String) -> BitcoinPaymentData {
        return paymentAddressParser.parse(paymentAddress: paymentAddress)
    }

    public func fee(for value: Int, toAddress: String? = nil, senderPay: Bool, feePriority: FeePriority = .medium) throws -> Int {
        return try transactionBuilder.fee(for: value, feeRate: getFeeRate(priority: feePriority), senderPay: senderPay, address: toAddress)
    }

    public var receiveAddress: String {
        return (try? addressManager.receiveAddress()) ?? ""
    }

    public var debugInfo: String {
        return dataProvider.debugInfo
    }

    private func getFeeRate(priority: FeePriority) -> Int {
        switch priority {
        case .lowest:
            return dataProvider.feeRate.low
        case .low:
            return (dataProvider.feeRate.low + dataProvider.feeRate.medium) / 2
        case .medium:
            return dataProvider.feeRate.medium
        case .high:
            return (dataProvider.feeRate.medium + dataProvider.feeRate.high) / 2
        case .highest:
            return dataProvider.feeRate.high
        case .custom(let value):
            return value
        }
    }

}

extension BitcoinCore: IDataProviderDelegate {

    func transactionsUpdated(inserted: [TransactionInfo], updated: [TransactionInfo]) {
        delegateQueue.async { [weak self] in
            if let kit = self {
                kit.delegates.forEach { $0.transactionsUpdated(inserted: inserted, updated: updated) }
            }
        }
    }

    func transactionsDeleted(hashes: [String]) {
        delegateQueue.async { [weak self] in
            self?.delegates.forEach { $0.transactionsDeleted(hashes: hashes) }
        }
    }

    func balanceUpdated(balance: Int) {
        delegateQueue.async { [weak self] in
            if let kit = self {
                kit.delegates.forEach { $0.balanceUpdated(balance: balance) }
            }
        }
    }

    func lastBlockInfoUpdated(lastBlockInfo: BlockInfo) {
        delegateQueue.async { [weak self] in
            if let kit = self {
                kit.delegates.forEach { $0.lastBlockInfoUpdated(lastBlockInfo: lastBlockInfo) }
            }
        }
    }

}

extension BitcoinCore: IKitStateProviderDelegate {
    func handleKitStateUpdate(state: KitState) {
        delegateQueue.async { [weak self] in
            self?.delegates.forEach { $0.kitStateUpdated(state: state) }
        }
    }
}

public protocol BitcoinCoreDelegate: class {
    func transactionsUpdated(inserted: [TransactionInfo], updated: [TransactionInfo])
    func transactionsDeleted(hashes: [String])
    func balanceUpdated(balance: Int)
    func lastBlockInfoUpdated(lastBlockInfo: BlockInfo)
    func kitStateUpdated(state: BitcoinCore.KitState)
}

extension BitcoinCoreDelegate {

    public func transactionsUpdated(inserted: [TransactionInfo], updated: [TransactionInfo]) {}
    public func transactionsDeleted(hashes: [String]) {}
    public func balanceUpdated(balance: Int) {}
    public func lastBlockInfoUpdated(lastBlockInfo: BlockInfo) {}
    public func kitStateUpdated(state: BitcoinCore.KitState) {}

}

extension BitcoinCore {

    public enum KitState {
        case synced
        case syncing(progress: Double)
        case notSynced
    }

}

extension BitcoinCore.KitState {

    public static func == (lhs: BitcoinCore.KitState, rhs: BitcoinCore.KitState) -> Bool {
        switch (lhs, rhs) {
        case (.synced, .synced), (.notSynced, .notSynced):
            return true
        case (.syncing(progress: let leftProgress), .syncing(progress: let rightProgress)):
            return leftProgress == rightProgress
        default:
            return false
        }
    }

}
