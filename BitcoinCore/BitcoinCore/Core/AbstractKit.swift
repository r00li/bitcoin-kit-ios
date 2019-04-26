import Foundation
import RxSwift

open class AbstractKit {
    public var bitcoinCore: BitcoinCore
    public var network: INetwork

    public init(bitcoinCore: BitcoinCore, network: INetwork) {
        self.bitcoinCore = bitcoinCore
        self.network = network
    }
}

extension AbstractKit {

    public func start() throws {
        try bitcoinCore.start()
    }

    public func clear() throws {
        try bitcoinCore.clear()
    }

    public var lastBlockInfo: BlockInfo? {
        return bitcoinCore.lastBlockInfo
    }

    public var balance: Int {
        return bitcoinCore.balance
    }

    public var syncState: BitcoinCore.KitState {
        return bitcoinCore.syncState
    }

    public func transactions(fromHash: String? = nil, limit: Int? = nil) -> Single<[TransactionInfo]> {
        return bitcoinCore.transactions(fromHash: fromHash, limit: limit)
    }

    public func send(to address: String, value: Int, feePriority: FeePriority = .medium) throws {
        try bitcoinCore.send(to: address, value: value, feePriority: feePriority)
    }

    func validate(address: String) throws {
        try bitcoinCore.validate(address: address)
    }

    func parse(paymentAddress: String) -> BitcoinPaymentData {
        return bitcoinCore.parse(paymentAddress: paymentAddress)
    }

    public func fee(for value: Int, toAddress: String? = nil, senderPay: Bool, feePriority: FeePriority = .medium) throws -> Int {
        return try bitcoinCore.fee(for: value, toAddress: toAddress, senderPay: senderPay, feePriority: feePriority)
    }

    public var receiveAddress: String {
        return bitcoinCore.receiveAddress
    }

    public var debugInfo: String {
        return bitcoinCore.debugInfo
    }

}
