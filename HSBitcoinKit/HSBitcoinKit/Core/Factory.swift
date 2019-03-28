class Factory: IFactory {

    func block(withHeader header: BlockHeader, previousBlock: Block) -> Block {
        return Block(withHeader: header, previousBlock: previousBlock)
    }

    func block(withHeader header: BlockHeader, height: Int) -> Block {
        return Block(withHeader: header, height: height)
    }

    func transaction(version: Int, lockTime: Int) -> Transaction {
        return Transaction(version: version, lockTime: lockTime)
    }

    func inputToSign(withPreviousOutput previousOutput: UnspentOutput, script: Data, sequence: Int) -> InputToSign {
        let input = Input(
                withPreviousOutputTxReversedHex: previousOutput.output.transactionHashReversedHex, previousOutputIndex: previousOutput.output.index,
                script: script, sequence: sequence
        )

        return InputToSign(input: input, previousOutput: previousOutput.output, previousOutputPublicKey: previousOutput.publicKey)
    }

    func output(withValue value: Int, index: Int, lockingScript script: Data = Data(), type: ScriptType, address: String?, keyHash: Data?, publicKey: PublicKey?) -> Output {
        return Output(withValue: value, index: index, lockingScript: script, type: type, address: address, keyHash: keyHash, publicKey: publicKey)
    }

    func peer(withHost host: String, network: INetwork, logger: Logger? = nil) -> IPeer {
        return Peer(host: host, network: network, connection: PeerConnection(host: host, network: network, logger: logger), connectionTimeoutManager: ConnectionTimeoutManager(), logger: logger)
    }

    func blockHash(withHeaderHash headerHash: Data, height: Int, order: Int = 0) -> BlockHash {
        return BlockHash(headerHash: headerHash, height: height, order: order)
    }

    func bloomFilter(withElements elements: [Data]) -> BloomFilter {
        return BloomFilter(elements: elements)
    }

}
