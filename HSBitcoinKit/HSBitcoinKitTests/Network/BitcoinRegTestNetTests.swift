import XCTest
import Cuckoo
@testable import HSBitcoinKit

class BitcoinRegTestNetTests:XCTestCase {

    private var mockNetwork: BitcoinMainNet!
    private var mockValidatorHelper: MockValidatorHelper!

    override func setUp() {
        super.setUp()

        mockValidatorHelper = MockValidatorHelper()
        mockNetwork = BitcoinMainNet(validatorFactory: mockValidatorHelper.mockFactory)
    }

    override func tearDown() {
        mockNetwork = nil
        mockValidatorHelper = nil

        super.tearDown()
    }

    func testValidate() {
        let block = TestData.firstBlock
        do {
            try mockNetwork.validate(block: block, previousBlock: TestData.checkpointBlock)
            verify(mockValidatorHelper.mockHeaderValidator, times(1)).validate(candidate: any(), block: any(), network: any())
        } catch let error {
            XCTFail("\(error) Exception Thrown")
        }
    }

}
