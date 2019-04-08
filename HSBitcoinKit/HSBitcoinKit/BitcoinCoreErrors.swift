import Foundation

public class BitcoinCoreErrors {

    public enum AddressConversion: Error {
        case invalidChecksum
        case invalidAddressLength
        case unknownAddressType
        case wrongAddressPrefix
    }

    enum PeerGroup: Error {
        case noConnectedPeers
        case peersNotSynced
    }

    enum MerkleBlockValidation: Error {
        case noMerkleBranch
        case wrongMerkleRoot
        case noTransactions
        case tooManyTransactions
        case moreHashesThanTransactions
        case matchedBitsFewerThanHashes
        case unnecessaryBits
        case notEnoughBits
        case notEnoughHashes
        case duplicatedLeftOrRightBranches
    }

}
