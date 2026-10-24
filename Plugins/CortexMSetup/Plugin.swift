// Plugin.swift

import Foundation
import PackagePlugin

@main
struct CortexMSetup: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        print()

        let options = try Options(parsing: arguments)
        if options.help { return print(Self.usage) }

        let root = context.package.directoryURL
        let runtime = try runtimeDirectory(in: context)
        let infoPath = try locateDeviceInfo(named: options.device, in: context)
        let device = try DeviceInfo.read(contentsOf: infoPath)
        let irqCount = device.interruptCount()

        guard let core = CoreSpec(svdCPU: device.cpu) else {
            throw SetupError.unsupportedCore(device.cpu)
        }

        guard irqCount > 0, irqCount <= core.maxInterrupts else {
            throw SetupError.badInterruptCount(irqCount, core.maxInterrupts)
        }

        if !device.fpuPresent, core.fpu != nil {
            print(
                """
                Warning: device.json reports no FPU, but Swift has no way \
                to disable floating-point code generation for \(core.cpu).
                """
            )
        }

        let deviceinfo = "core - \(device.cpu), FPU - \(device.fpuPresent ? "present" : "absent")"
        print("device:  \(options.device) \(deviceinfo)")
        print("         \(device.interrupts.count) named IRQs, \(irqCount) slots")
        print("")
        print("core:    \(core.cpu) fpu=\(core.fpu ?? "none") float-abi=\(core.floatABI)")
        print("triple:  \(core.swiftTriple)")
        print("")

        let templates = runtime.appending(path: "Templates")

        try write(
            contentsOf: templates.appending(path: "linkerscript.ld"),
            to: root.appending(path: "linkerscript.ld"),
            force: options.force,
        )

        try write(
            contentsOf: templates.appending(path: "memory.x"),
            to: root.appending(path: "memory.x"),
            force: options.force,
        )

        try writeString(
            substitute(
                try String(contentsOf: templates.appending(path: "device.x.in"), encoding: .utf8),
                [
                    "@PROVIDES@": provides(device: device, irqCount: irqCount)
                ],
            ),
            to: root.appending(path: "device.x"),
            force: options.force,
        )

        try writeString(
            substitute(
                try String(
                    contentsOf: templates.appending(path: "toolset.json.in"),
                    encoding: .utf8,
                ),
                [
                    "@CPU_XCC@": core.clangFlags.map { "\"-Xcc\", \"\($0)\"," }.joined(
                        separator: " "
                    ),
                    "@CPU_CC@": core.clangFlags.map { "\"\($0)\"," }.joined(separator: " "),
                    "@TARGET_CPU@": core.cpu,
                    "@IRQ_COUNT@": String(irqCount),
                ],
            ),
            to: root.appending(path: "toolset.json"),
            force: options.force,
        )

        try writeString(
            substitute(
                try String(contentsOf: templates.appending(path: "Makefile.in"), encoding: .utf8),
                [
                    "@TARGET@": options.product ?? context.package.products.first?.name ?? "App",
                    "@TRIPLE@": core.swiftTriple,
                    "@CLANG_TRIPLE@": core.clangTriple,
                    "@CPU_FLAGS@": core.clangFlags.joined(separator: " "),
                ],
            ),
            to: root.appending(path: "Makefile"),
            force: options.force,
        )
    }

    private func runtimeDirectory(in context: PluginContext) throws -> URL {
        let packageName = "swift-cortex-m"

        func search(_ dependencies: [PackageDependency]) -> URL? {
            for dependency in dependencies {
                if dependency.package.displayName == packageName {
                    return dependency.package.directoryURL
                }

                if let found = search(dependency.package.dependencies) {
                    return found
                }
            }
            return nil
        }

        // Running the plugin from inside swift-cortex-m itself
        if context.package.displayName == packageName {
            return context.package.directoryURL
        }

        guard let found = search(context.package.dependencies) else {
            throw SetupError.runtimeNotFound
        }

        return found
    }

    private func locateDeviceInfo(named name: String, in context: PluginContext) throws -> String {
        func module(in package: Package) -> Target? {
            if let target = package.targets.first(where: { $0.name == name }) {
                return target
            }

            for dependency in package.dependencies {
                if let target = module(in: dependency.package) {
                    return target
                }
            }

            return nil
        }

        guard let target = module(in: context.package) else {
            throw SetupError.deviceNotFound(name)
        }

        let path = target.directoryURL.appending(path: "device.json").path()

        guard FileManager.default.fileExists(atPath: path) else {
            throw SetupError.deviceNotFound(name)
        }

        return path
    }

    // MARK: Emitting

    private func provides(device: DeviceInfo, irqCount: Int) -> String {
        let namesBySlot = Dictionary(grouping: device.interrupts, by: \.value)
            .mapValues { $0.map { "\($0.key)_IRQHandler" }.sorted() }

        var blocks: [String] = []

        for slot in 0..<irqCount {
            let names: [String] = namesBySlot[slot] ?? []
            let chain: [String] = ["Default_Handler"] + names + ["IRQ\(slot)_Handler"]
            var lines: [String] = zip(chain.dropFirst(), chain).map { provide($0, $1) }

            if names.isEmpty { lines[0] += " /* unnamed */" }

            blocks.append(lines.joined(separator: "\n"))
        }

        return blocks.joined(separator: "\n\n")
    }

    private func provide(_ symbol: String, _ value: String) -> String {
        pad("PROVIDE(\(symbol)") + " = \(value));"
    }

    private func pad(_ text: String, to column: Int = 38) -> String {
        text + String(repeating: " ", count: max(1, column - text.count))
    }

    private func substitute(_ template: String, _ replacements: [String: String]) -> String {
        var out = template

        for (key, value) in replacements {
            out = out.replacingOccurrences(of: key, with: value)
        }

        return out
    }

    private func write(contentsOf source: URL, to destination: URL, force: Bool) throws {
        try writeString(
            try String(contentsOf: source, encoding: .utf8),
            to: destination,
            force: force,
        )
    }

    private func writeString(_ contents: String, to destination: URL, force: Bool) throws {
        let name = destination.lastPathComponent

        if FileManager.default.fileExists(atPath: destination.path()), !force {
            print("- skipped: \(name)\t(already exists; pass --force to overwrite)")
            return
        }

        try contents.write(to: destination, atomically: true, encoding: .utf8)
        print("- wrote:   \(name)")
    }

    static let usage = """
        swift package cortex-m-setup [options]

        Writes linkerscript.ld, memory.x, device.x, toolset.json and a Makefile.

        Required:
            --device <NAME>        target module name, e.g. STM32G431.

        Options:
            --product <name>       executable product name for the Makefile
            --force                overwrite files that already exist
        """
}

struct Options {
    var help: Bool
    var force: Bool
    var device: String
    var product: String?

    init(parsing arguments: [String]) throws {
        var args = ArgumentExtractor(arguments)

        self.help = args.extractFlag(named: "help") > 0 || arguments.contains("-h")
        self.force = args.extractFlag(named: "force") > 0
        self.product = args.extractOption(named: "product").last
        let device = args.extractOption(named: "device").last

        guard help || args.remainingArguments.isEmpty else {
            throw SetupError.unknownArguments(args.remainingArguments)
        }

        guard help || device != nil else {
            throw SetupError.missingDevice
        }

        self.device = device ?? ""
    }
}

enum SetupError: Error, CustomStringConvertible {
    case runtimeNotFound
    case deviceNotFound(String)
    case unsupportedCore(String)
    case missingDevice
    case badInterruptCount(Int, Int)
    case unknownArguments([String])

    var description: String {
        switch self {
        case .runtimeNotFound:
            "Could not find swift-cortex-m in the dependency graph"
        case .deviceNotFound(let name):
            "No module '\(name)' with a device.json in the dependency graph"
        case .unsupportedCore(let name):
            "File device.json reports '\(name)', which this package has no mapping for"
        case .missingDevice:
            "--device <NAME> is required. Run with --help for the options"
        case .badInterruptCount(let count, let max):
            "File device.json describes \(count) interrupts, outside 1...\(max) for this core"
        case .unknownArguments(let arguments):
            "Unrecognized: \(arguments.joined(separator: " ")). Run with --help for the options."
        }
    }
}
