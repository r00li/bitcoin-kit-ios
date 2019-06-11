import BitcoinCore
import BigInt

class DarkGravityWaveValidator: IBlockValidator {
    private let difficultyEncoder: IDashDifficultyEncoder
    private let blockHelper: IDashBlockValidatorHelper

    private let heightInterval: Int
    private let targetTimeSpan: Int
    private let maxTargetBits: Int
    private let firstCheckpointHeight: Int
    private let powDGWHeight: Int

    init(encoder: IDashDifficultyEncoder, blockHelper: IDashBlockValidatorHelper, heightInterval: Int, targetTimeSpan: Int, maxTargetBits: Int, firstCheckpointHeight: Int, powDGWHeight: Int) {
        self.difficultyEncoder = encoder
        self.blockHelper = blockHelper

        self.heightInterval = heightInterval
        self.targetTimeSpan = targetTimeSpan
        self.maxTargetBits = maxTargetBits
        self.firstCheckpointHeight = firstCheckpointHeight
        self.powDGWHeight = powDGWHeight
    }

    func validate(block: Block, previousBlock: Block) throws {
        guard previousBlock.height >= firstCheckpointHeight + heightInterval else {             // we must trust first 24 blocks from checkpoint, because can't calculate it's bits
            return
        }

        let blockTarget = difficultyEncoder.decodeCompact(bits: previousBlock.bits)

        var actualTimeSpan = 0
        var avgTargets = blockTarget
        var prevBlock: Block? = blockHelper.previous(for: previousBlock, count: 1)

        for blockCount in 2...heightInterval {
            guard let currentBlock = prevBlock else {
                throw BitcoinCoreErrors.BlockValidation.noPreviousBlock
            }
            let currentTarget = difficultyEncoder.decodeCompact(bits: currentBlock.bits)
            avgTargets = (avgTargets * BigInt(blockCount) + currentTarget) / BigInt(blockCount + 1)

            if blockCount < heightInterval {
                prevBlock = blockHelper.previous(for: currentBlock, count: 1)
            } else {
                actualTimeSpan = previousBlock.timestamp - currentBlock.timestamp
            }
        }
        var darkTarget = avgTargets
        if (actualTimeSpan < targetTimeSpan / 3) {
            actualTimeSpan = targetTimeSpan / 3
        } else if (actualTimeSpan > targetTimeSpan * 3) {
            actualTimeSpan = targetTimeSpan * 3
        }

        darkTarget = darkTarget * BigInt(actualTimeSpan) / BigInt(targetTimeSpan)
        let compact = min(maxTargetBits, difficultyEncoder.encodeCompact(from: darkTarget))

        if compact != block.bits {
            throw BitcoinCoreErrors.BlockValidation.notEqualBits
        }
    }

    func isBlockValidatable(block: Block, previousBlock: Block) -> Bool {
        return block.height >= powDGWHeight
    }

}
