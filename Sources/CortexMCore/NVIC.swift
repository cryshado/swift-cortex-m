// NVIC.swift

import _Volatile

public enum NVIC {
    private static let iserBase: UInt = 0xE000_E100  // Interrupt Set-Enable
    private static let icerBase: UInt = 0xE000_E180  // Interrupt Clear-Enable

    /// One 32-bit register per 32 interrupts
    private static func register(_ base: UInt, _ number: UInt32) -> Register32 {
        .init(unsafeBitPattern: base + UInt(number >> 5) * 4)
    }

    public static func enable(_ number: UInt32) {
        register(iserBase, number).store(1 << (number & 0x1F))
    }

    public static func disable(_ number: UInt32) {
        register(icerBase, number).store(1 << (number & 0x1F))
        dataSynchronizationBarrier()
        instructionSynchronizationBarrier()
    }

    public static func enable<I: RawRepresentable>(_ interrupt: I)
    where I.RawValue: BinaryInteger {
        enable(UInt32(interrupt.rawValue))
    }

    public static func disable<I: RawRepresentable>(_ interrupt: I)
    where I.RawValue: BinaryInteger {
        disable(UInt32(interrupt.rawValue))
    }
}
