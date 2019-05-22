class TransactionCreator {
    enum CreationError: Error {
        case transactionAlreadyExists
    }

    let transactionBuilder: ITransactionBuilder
    let transactionProcessor: ITransactionProcessor
    let transactionSender: ITransactionSender

    init(transactionBuilder: ITransactionBuilder, transactionProcessor: ITransactionProcessor, transactionSender: ITransactionSender) {
        self.transactionBuilder = transactionBuilder
        self.transactionProcessor = transactionProcessor
        self.transactionSender = transactionSender
    }

}

extension TransactionCreator: ITransactionCreator {

    func create(to address: String, value: Int, feeRate: Int, senderPay: Bool) throws {
        try transactionSender.verifyCanSend()

        let transaction = try transactionBuilder.buildTransaction(value: value, feeRate: feeRate, senderPay: senderPay, toAddress: address)
        try transactionProcessor.processCreated(transaction: transaction)

        try transactionSender.send(pendingTransaction: transaction)
    }

}
