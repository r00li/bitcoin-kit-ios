import Foundation
import HSBitcoinKit
import RxSwift

class Manager {
    enum KitType: Int { case bitcoin, bitcoinCash, dash }

    static let shared = Manager()

    private let keyWords = "mnemonic_words"
    private let keyKitType = "kit_type"

    var kit: AbstractKit!

    let kitInitializationCompleted = BehaviorSubject<Bool>(value: false)

    let balanceSubject = PublishSubject<Int>()
    let lastBlockInfoSubject = PublishSubject<BlockInfo>()
    let progressSubject = PublishSubject<BitcoinCore.KitState>()
    let transactionsSubject = PublishSubject<Void>()

    init() {
        if let words = savedWords, let kitType = savedKitType  {
            initWalletKit(words: words, kitType: kitType)
        }
    }

    func login(words: [String], kitType: KitType = .bitcoin) {
        save(words: words)
        save(kitType: kitType)
        initWalletKit(words: words, kitType: kitType)
    }

    func logout() {
        do {
            try kit.clear()
        } catch {
            print("WalletKit Clear Error: \(error)")
        }

        clearWords()
        clearKitType()

        kitInitializationCompleted.onNext(false)
        kit = nil
    }

    private func initWalletKit(words: [String], kitType: KitType) {
        switch kitType {
        case .bitcoin:
            let kit =  try! BitcoinKit(withPublicKey: "tpubDDYDWoUhYtXEFLqrfdL4UeKCBPLMDZBb2Svfi7UeCvEt4pWHiBD2AkvVYCUBsk4uHo9yYMJc1uQjtjaLPTx8RBKuZv844rmnZ9CsAb41fJ4", walletId: "SomeId3", testMode: true, minLogLevel: .verbose)
            //let kit = try! BitcoinKit(withWords: words, walletId: "SomeId", networkType: BitcoinKit.NetworkType.testNet, minLogLevel: .verbose)
            self.kit = kit
            kit.delegate = self
        case .bitcoinCash:
            let kit = try! BitcoinCashKit(withWords: words, walletId: "SomeId", networkType: BitcoinCashKit.NetworkType.testNet, minLogLevel: .verbose)
            self.kit = kit
            kit.delegate = self
        case .dash:
            let kit = try! DashKit(withWords: words, walletId: "SomeId", networkType: DashKit.NetworkType.testNet, minLogLevel: .verbose)
            self.kit = kit
            kit.delegate = self
        }

        kitInitializationCompleted.onNext(true)
    }

    private var savedWords: [String]? {
        if let wordsString = UserDefaults.standard.value(forKey: keyWords) as? String {
            return wordsString.split(separator: " ").map(String.init)
        }
        return nil
    }

    private func save(words: [String]) {
        UserDefaults.standard.set(words.joined(separator: " "), forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

    private func clearWords() {
        UserDefaults.standard.removeObject(forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

    private var savedKitType: KitType? {
        if let kitType = UserDefaults.standard.value(forKey: keyKitType) as? Int {
            return KitType.init(rawValue: kitType)
        }
        return nil
    }

    private func save(kitType: KitType) {
        UserDefaults.standard.set(kitType.rawValue, forKey: keyKitType)
        UserDefaults.standard.synchronize()
    }

    private func clearKitType() {
        UserDefaults.standard.removeObject(forKey: keyKitType)
        UserDefaults.standard.synchronize()
    }

}

extension Manager: BitcoinCoreDelegate {
    public func transactionsUpdated(inserted: [TransactionInfo], updated: [TransactionInfo]) {
        transactionsSubject.onNext(())
    }

    public func balanceUpdated(balance: Int) {
        balanceSubject.onNext(balance)
    }

    public func transactionsDeleted(hashes: [String]) {
        // transactionsSubject.onNext(())
    }

    public func lastBlockInfoUpdated(lastBlockInfo: BlockInfo) {
        lastBlockInfoSubject.onNext(lastBlockInfo)
    }

    public func kitStateUpdated(state: BitcoinCore.KitState) {
        progressSubject.onNext(state)
    }

}
