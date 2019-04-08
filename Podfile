platform :ios, '11.0'
use_frameworks!

inhibit_all_warnings!

workspace 'HSBitcoinKit'

project 'HSBitcoinKitDemo/HSBitcoinKitDemo'
project 'HSBitcoinKit/HSBitcoinKit'


def internal_pods
  #pod 'HSCryptoKit', '~> 1.3.0'
  pod 'HSCryptoX11', git: 'https://github.com/horizontalsystems/crypto-x11-ios'
  pod 'HSHDWalletKit', :git => 'https://github.com/r00li/hd-wallet-kit-ios.git', :branch => 'master'
end

def kit_pods
  internal_pods

  pod 'Alamofire', '~> 4.8.0'
  pod 'ObjectMapper', '~> 3.4.0'

  pod 'RxSwift', '~> 4.0'

  pod 'BigInt', '~> 3.1.0'

  pod 'GRDB.swift', '~> 3.6.2'
end

target :HSBitcoinKitDemo do
  project 'HSBitcoinKitDemo/HSBitcoinKitDemo'
  kit_pods
end

target :HSBitcoinKit do
  project 'HSBitcoinKit/HSBitcoinKit'
  kit_pods
end

target :HSBitcoinKitTests do
  project 'HSBitcoinKit/HSBitcoinKit'

  internal_pods
  pod 'Quick'
  pod 'Nimble'
  pod 'Cuckoo'
  pod 'RxBlocking', '~> 4.0'
end
