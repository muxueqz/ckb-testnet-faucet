//
//  CKBService.swift
//  App
//
//  Created by 翟泉 on 2019/3/12.
//

import Foundation
import CKB

public class CKBService {
    let api: APIClient

    static var shared = CKBService()

    init() {
        api = APIClient()
    }
    
    public func faucet(address: String) throws -> H256 {
        guard let publicKeyHash = AddressGenerator(network: .testnet).publicKeyHash(for: address) else { throw Error.invalidAddress }
        let lock = Script(version: 0, args: [publicKeyHash], binaryHash: try api.systemScriptCellHash())
        let asw = try AlwaysSuccessWallet(api: api)
        return try asw.sendCapacity(targetLock: lock, capacity: 10000)
    }

    public static func privateToAddress(_ privateKey: String) throws -> String {
        return try publicToAddress(try privateToPublic(privateKey))
    }

    public static func publicToAddress(_ publicKey: String) throws -> String {
        if publicKey.hasPrefix("0x") && publicKey.lengthOfBytes(using: .utf8) == 68 {
            return AddressGenerator(network: .testnet).address(for: publicKey)
        } else if publicKey.lengthOfBytes(using: .utf8) == 66 {
            return AddressGenerator(network: .testnet).address(for: publicKey)
        } else {
            throw Error.invalidPublicKey
        }
    }

    public static func privateToPublic(_ privateKey: String) throws -> String {
        if privateKey.hasPrefix("0x") && privateKey.lengthOfBytes(using: .utf8) == 66 {
            return Utils.publicToAddress(String(privateKey.dropFirst(2)))
        } else if privateKey.lengthOfBytes(using: .utf8) == 64 {
            return Utils.privateToPublic(privateKey)
        } else {
            throw Error.invalidPrivateKey
        }
    }

    public static func generatePrivateKey() -> String {
        var data = Data(repeating: 0, count: 32)
        #if os(OSX)
        data.withUnsafeMutableBytes({ _ = SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress! ) })
        #else
        for _ in 0..<32 {
            data.append(UInt8.random(in: UInt8.min...UInt8.max))
        }
        #endif
        return data.toHexString()
    }
}

extension CKBService {
    enum Error: String, Swift.Error {
        case invalidPrivateKey = "Invalid privateKey"
        case invalidPublicKey = "Invalid publicKey"
        case invalidAddress = "Invalid address"
    }
}
