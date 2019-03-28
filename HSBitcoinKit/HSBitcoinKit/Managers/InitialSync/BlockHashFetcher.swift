import RxSwift

class BlockHashFetcher {
    private let addressSelector: IAddressSelector
    private let apiManager: IBCoinApi
    private let helper: IBlockHashFetcherHelper

    init(addressSelector: IAddressSelector, apiManager: IBCoinApi, helper: IBlockHashFetcherHelper) {
        self.addressSelector = addressSelector
        self.apiManager = apiManager
        self.helper = helper
    }

}

extension BlockHashFetcher: IBlockHashFetcher {

    func getBlockHashes(publicKeys: [PublicKey]) -> Observable<(responses: [BlockHash], lastUsedIndex: Int)> {
        let addresses = publicKeys.map {
            addressSelector.getAddressVariants(publicKey: $0)
        }

        return apiManager.getTransactions(addresses: addresses.flatMap { $0 }).map { [weak self] transactionResponses -> (responses: [BlockHash], lastUsedIndex: Int) in
            if transactionResponses.isEmpty {
                return (responses: [], lastUsedIndex: -1)
            }

            let lastUsedIndex = self?.helper.lastUsedIndex(addresses: addresses, outputs: transactionResponses.flatMap { $0.txOutputs })

            let blockHashes: [BlockHash] = transactionResponses.compactMap {
                BlockHash(headerHashReversedHex: $0.blockHash, height: $0.blockHeight, sequence: 0)
            }

            return (responses: blockHashes, lastUsedIndex: lastUsedIndex ?? -1)
        }
    }

}
