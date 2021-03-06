import Foundation
import RxSwift

open class AbstractKit {
    public var bitcoinCore: BitcoinCore
    public var network: INetwork

    public init(bitcoinCore: BitcoinCore, network: INetwork) {
        self.bitcoinCore = bitcoinCore
        self.network = network
    }

    open func start() {
        bitcoinCore.start()
    }

    open func stop() {
        bitcoinCore.stop()
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

    open func send(to address: String, value: Int, feeRate: Int) throws {
        try bitcoinCore.send(to: address, value: value, feeRate: feeRate)
    }

    open func validate(address: String) throws {
        try bitcoinCore.validate(address: address)
    }

    open func parse(paymentAddress: String) -> BitcoinPaymentData {
        return bitcoinCore.parse(paymentAddress: paymentAddress)
    }

    open func fee(for value: Int, toAddress: String? = nil, senderPay: Bool, feeRate: Int) throws -> Int {
        return try bitcoinCore.fee(for: value, toAddress: toAddress, senderPay: senderPay, feeRate: feeRate)
    }

    open func receiveAddress(for type: ScriptType) -> String {
        return bitcoinCore.receiveAddress(for: type)
    }

    open var debugInfo: String {
        return bitcoinCore.debugInfo
    }

}
