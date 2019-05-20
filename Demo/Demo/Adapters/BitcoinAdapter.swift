import BitcoinKit
import BitcoinCore
import RxSwift

class BitcoinAdapter: BaseAdapter {
    private let bitcoinKit: BitcoinKit

    init(words: [String], testMode: Bool) {
        //let networkType: BitcoinKit.NetworkType = testMode ? .testNet : .mainNet
        //bitcoinKit = try! BitcoinKit(withWords: words, walletId: "walletId", networkType: networkType, minLogLevel: Configuration.shared.minLogLevel)
        bitcoinKit = try! BitcoinKit(withPublicKey: "tpubDDYDWoUhYtXEFLqrfdL4UeKCBPLMDZBb2Svfi7UeCvEt4pWHiBD2AkvVYCUBsk4uHo9yYMJc1uQjtjaLPTx8RBKuZv844rmnZ9CsAb41fJ4", walletId: "SomeId3", testMode: true, minLogLevel: .verbose)

        super.init(name: "Bitcoin", coinCode: "BTC", abstractKit: bitcoinKit)
        bitcoinKit.delegate = self
    }

    class func clear() {
        try? BitcoinKit.clear()
    }
}

extension BitcoinAdapter: BitcoinCoreDelegate {

    func transactionsUpdated(inserted: [TransactionInfo], updated: [TransactionInfo]) {
        transactionsSignal.notify()
    }

    func transactionsDeleted(hashes: [String]) {
        transactionsSignal.notify()
    }

    func balanceUpdated(balance: Int) {
        balanceSignal.notify()
    }

    func lastBlockInfoUpdated(lastBlockInfo: BlockInfo) {
        lastBlockSignal.notify()
    }

    public func kitStateUpdated(state: BitcoinCore.KitState) {
        syncStateSignal.notify()
    }

}
