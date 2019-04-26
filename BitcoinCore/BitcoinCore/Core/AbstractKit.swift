import Foundation
import RxSwift

open class AbstractKit {
    public var bitcoinCore: BitcoinCore
    public var network: INetwork

    public init(bitcoinCore: BitcoinCore, network: INetwork) {
        self.bitcoinCore = bitcoinCore
        self.network = network
    }

    open func start() throws {
        try bitcoinCore.start()
    }

    open func clear() throws {
        try bitcoinCore.clear()
    }

    open var lastBlockInfo: BlockInfo? {
        return bitcoinCore.lastBlockInfo
    }

    open var balance: Int {
        return bitcoinCore.balance
    }

    open var syncState: BitcoinCore.KitState {
        return bitcoinCore.syncState
    }

    open func transactions(fromHash: String? = nil, limit: Int? = nil) -> Single<[TransactionInfo]> {
        return bitcoinCore.transactions(fromHash: fromHash, limit: limit)
    }

    open func send(to address: String, value: Int, feePriority: FeePriority = .medium) throws {
        try bitcoinCore.send(to: address, value: value, feePriority: feePriority)
    }

    open func validate(address: String) throws {
        try bitcoinCore.validate(address: address)
    }

    open func parse(paymentAddress: String) -> BitcoinPaymentData {
        return bitcoinCore.parse(paymentAddress: paymentAddress)
    }

    open func fee(for value: Int, toAddress: String? = nil, senderPay: Bool, feePriority: FeePriority = .medium) throws -> Int {
        return try bitcoinCore.fee(for: value, toAddress: toAddress, senderPay: senderPay, feePriority: feePriority)
    }

    open var receiveAddress: String {
        return bitcoinCore.receiveAddress
    }

    open var debugInfo: String {
        return bitcoinCore.debugInfo
    }

}
