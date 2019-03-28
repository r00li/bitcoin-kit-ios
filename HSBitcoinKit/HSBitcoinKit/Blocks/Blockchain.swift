class Blockchain {
    private let storage: IStorage
    private let network: INetwork
    private let factory: IFactory
    weak var listener: IBlockchainDataListener?

    init(storage: IStorage, network: INetwork, factory: IFactory, listener: IBlockchainDataListener? = nil) {
        self.storage = storage
        self.network = network
        self.factory = factory
        self.listener = listener
    }

    private func unstaleAllBlocks() throws {
        for block in storage.blocks(stale: true) {
            block.stale = false
            try storage.update(block: block)
        }
    }

}

extension Blockchain: IBlockchain {

    func connect(merkleBlock: MerkleBlock) throws -> Block {
        if let existingBlock = storage.block(byHashHex: merkleBlock.headerHashReversedHex) {
            return existingBlock
        }

        guard let previousBlock = storage.block(byHashHex: merkleBlock.header.previousBlockHeaderHash.reversedHex) else {
            throw BlockValidatorError.noPreviousBlock
        }

        // Validate and chain new blocks
        let block = factory.block(withHeader: merkleBlock.header, previousBlock: previousBlock)
        try network.validate(block: block, previousBlock: previousBlock)
        block.stale = true

        try storage.add(block: block)
        listener?.onInsert(block: block)

        return block
    }

    func forceAdd(merkleBlock: MerkleBlock, height: Int) throws -> Block {
        let block = factory.block(withHeader: merkleBlock.header, height: height)
        try storage.add(block: block)

        listener?.onInsert(block: block)

        return block
    }

    func handleFork() {
        guard let firstStaleHeight = storage.block(stale: true, sortedHeight: "ASC")?.height else {
            return
        }

        let lastNotStaleHeight = storage.block(stale: false, sortedHeight: "DESC")?.height ?? 0

        try? storage.inTransaction {
            if (firstStaleHeight <= lastNotStaleHeight) {
                let lastStaleHeight = storage.block(stale: true, sortedHeight: "DESC")?.height ?? firstStaleHeight

                if (lastStaleHeight > lastNotStaleHeight) {
                    let notStaleBlocks = storage.blocks(heightGreaterThanOrEqualTo: firstStaleHeight, stale: false)
                    try deleteBlocks(blocks: notStaleBlocks)
                    try unstaleAllBlocks()
                } else {
                    let staleBlocks = storage.blocks(stale: true)
                    try deleteBlocks(blocks: staleBlocks)
                }
            } else {
                try unstaleAllBlocks()
            }
        }
    }

    func deleteBlocks(blocks: [Block]) throws {
        let hashes =  blocks.reduce(into: [String](), { acc, block in
            acc.append(contentsOf: storage.transactions(ofBlock: block).map { $0.dataHashReversedHex })
        })

        try storage.delete(blocks: blocks)
        listener?.onDelete(transactionHashes: hashes)
    }

}
