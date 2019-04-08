// todo identical code with transactionMessageParser
class TransactionLockMessageParser: ListElement<Data, IMessage> {
    override var id: String { return "ix" }

    override func process(_ request: Data) -> IMessage? {
        return TransactionLockMessage(transaction: TransactionSerializer.deserialize(data: request))
    }

}
