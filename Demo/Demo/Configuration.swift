import BitcoinCore

class Configuration {
    static let shared = Configuration()

    let minLogLevel: Logger.Level = .error
    let testNet = true
    let defaultWords = "used ugly meat glad balance divorce inner artwork hire invest already piano"
}
