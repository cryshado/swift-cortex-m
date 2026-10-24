// DeviceInfo.swift

import Foundation

struct DeviceInfo: Decodable {
    let cpu: String
    let fpuPresent: Bool
    let fpuDP: Bool?

    let interrupts: [String: Int]

    func interruptCount() -> Int {
        guard
            let highest: Dictionary<String, Int>.Values.Element = interrupts.values.max()
        else {
            return 0
        }

        return highest + 1
    }

    static func read(contentsOf path: String) throws -> DeviceInfo {
        guard let data = FileManager.default.contents(atPath: path) else {
            throw DeviceInfoError.unreadable(path)
        }

        let device: DeviceInfo

        do {
            device = try JSONDecoder().decode(DeviceInfo.self, from: data)
        } catch {
            throw DeviceInfoError.undecodable(path, error)
        }

        if let name: Dictionary<String, Int>.Keys.Element =
            device.interrupts.keys.first(where: { !$0.isCIdentifier })
        {
            throw DeviceInfoError.invalidInterruptName(path, name)
        }

        return device
    }
}

enum DeviceInfoError: Error, CustomStringConvertible {
    case unreadable(String)
    case undecodable(String, any Error)
    case invalidInterruptName(String, String)

    var description: String {
        switch self {
        case .unreadable(let path): "could not read \(path)"
        case .undecodable(let path, let error): "could not decode \(path): \(error)"
        case .invalidInterruptName(let path, let name):
            "\(path): interrupt name '\(name)' is not a valid C identifier"
        }
    }
}

extension String {
    var isCIdentifier: Bool {
        guard let first, first.isASCII, first.isLetter || first == "_" else { return false }
        return allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_") }
    }
}
