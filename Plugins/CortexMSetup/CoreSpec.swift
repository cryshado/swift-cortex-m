// CoreSpec.swift

struct CoreSpec {
    enum Architecture {
        case armv6m
        case armv7em
        case armv8mMain
        case armv81mMain

        /// Swift's spelling
        var swiftTriple: String {
            switch self {
            case .armv6m: "armv6m-none-none-eabi"
            case .armv7em: "armv7em-none-none-eabi"
            case .armv8mMain: "armv8m.main-none-none-eabi"
            case .armv81mMain: "armv8.1m.main-none-none-eabi"
            }
        }

        /// Clang's spelling of the same target
        var clangTriple: String {
            switch self {
            case .armv6m: "armv6m-none-eabi"
            case .armv7em: "armv7em-none-eabi"
            case .armv8mMain: "armv8m.main-none-eabi"
            case .armv81mMain: "armv8.1m.main-none-eabi"
            }
        }

        /// The architected NVIC limit
        var maxInterrupts: Int {
            switch self {
            case .armv6m: 32
            case .armv7em: 240
            case .armv8mMain, .armv81mMain: 480
            }
        }
    }

    /// Passed to Swift as `-target-cpu` and to clang as `-mcpu=`
    let cpu: String

    let architecture: Architecture

    /// Clang's `-mfpu=`; `nil` for a core without an FPU
    let fpu: String?

    /// Whether the flags make Swift emit double-precision FPU instructions
    var usesDoublePrecisionFPU: Bool { fpu == "fpv5-d16" }

    var swiftTriple: String { architecture.swiftTriple }
    var clangTriple: String { architecture.clangTriple }
    var maxInterrupts: Int { architecture.maxInterrupts }
    var floatABI: String { fpu == nil ? "soft" : "softfp" }

    var clangFlags: [String] {
        var flags = ["-mcpu=\(cpu)"]

        if let fpu {
            flags.append("-mfpu=\(fpu)")
        }

        flags.append("-mfloat-abi=\(floatABI)")

        return flags
    }

    init?(svdCPU name: String) {
        switch name {
        case "CM0": self.init(cpu: "cortex-m0", architecture: .armv6m, fpu: nil)
        case "CM0+": self.init(cpu: "cortex-m0plus", architecture: .armv6m, fpu: nil)
        case "CM1": self.init(cpu: "cortex-m1", architecture: .armv6m, fpu: nil)

        // No armv7m embedded stdlib ships, so the M3 builds for ARMv7E-M and
        // relies on -target-cpu to stay within the ARMv7-M instruction set
        case "CM3": self.init(cpu: "cortex-m3", architecture: .armv7em, fpu: nil)

        case "CM4": self.init(cpu: "cortex-m4", architecture: .armv7em, fpu: "fpv4-sp-d16")

        // LLVM's cortex-m7 is double-precision. A single-precision-only M7 part
        // cannot be expressed, and Swift would emit .f64 instructions for it
        case "CM7": self.init(cpu: "cortex-m7", architecture: .armv7em, fpu: "fpv5-d16")

        case "CM33": self.init(cpu: "cortex-m33", architecture: .armv8mMain, fpu: "fpv5-sp-d16")
        case "CM35P": self.init(cpu: "cortex-m33", architecture: .armv8mMain, fpu: "fpv5-sp-d16")
        case "CM55": self.init(cpu: "cortex-m55", architecture: .armv81mMain, fpu: "fpv5-d16")
        case "CM85": self.init(cpu: "cortex-m85", architecture: .armv81mMain, fpu: "fpv5-d16")
        default: return nil
        }
    }

    private init(cpu: String, architecture: Architecture, fpu: String?) {
        self.cpu = cpu
        self.architecture = architecture
        self.fpu = fpu
    }
}
