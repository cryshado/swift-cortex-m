// SysTick.swift

import _Volatile

/// SysTick: the 24-bit countdown timer built into every Cortex-M
public enum SysTick {
    public enum ClockSource {
        /// The processor clock
        case core

        /// An implementation-defined reference clock
        case external
    }

    public enum Error: Swift.Error {
        /// The reload value was `0` or wider than 24 bits
        case reloadOutOfRange(UInt32)
    }

    /// The largest reload value the 24-bit counter can hold
    public static let maximumReload: UInt32 = 0x00FF_FFFF

    // MARK: Registers

    // Control and Status, Reload Value, Current Value, Calibration Value
    private static var csr: Register32 { .init(unsafeBitPattern: 0xE000_E010) }
    private static var rvr: Register32 { .init(unsafeBitPattern: 0xE000_E014) }
    private static var cvr: Register32 { .init(unsafeBitPattern: 0xE000_E018) }
    private static var calib: Register32 { .init(unsafeBitPattern: 0xE000_E01C) }

    private static let enableBit: UInt32 = 1 << 0  // CSR.ENABLE
    private static let tickIntBit: UInt32 = 1 << 1  // CSR.TICKINT
    private static let clkSourceBit: UInt32 = 1 << 2  // CSR.CLKSOURCE
    private static let countFlagBit: UInt32 = 1 << 16  // CSR.COUNTFLAG
    private static let tenmsMask: UInt32 = 0x00FF_FFFF  // CALIB.TENMS
    private static let skewBit: UInt32 = 1 << 30  // CALIB.SKEW
    private static let noRefBit: UInt32 = 1 << 31  // CALIB.NOREF

    /// Read-modify-write of the control register, the read clears COUNTFLAG
    private static func modifyCSR(set: UInt32 = 0, clear: UInt32 = 0) {
        csr.store((csr.load() & ~clear) | set)
    }

    private static func validate(reload: UInt32) throws(Error) {
        guard (1...maximumReload).contains(reload) else {
            throw Error.reloadOutOfRange(reload)
        }
    }

    // MARK: Counter

    /// Starts counting down from the current value. Set the reload and clear
    /// the current value first, or use `start` which does all three in order
    public static func enableCounter() {
        modifyCSR(set: enableBit)
    }

    public static func disableCounter() {
        modifyCSR(clear: enableBit)
    }

    /// Whether the counter is running, reading this clears COUNTFLAG
    public static var isCounterEnabled: Bool {
        csr.load() & enableBit != 0
    }

    // MARK: Interrupt

    /// Raises the SysTick exception (`SysTick_Handler`)
    /// each time the counter wraps to zero
    public static func enableInterrupt() {
        modifyCSR(set: tickIntBit)
    }

    public static func disableInterrupt() {
        modifyCSR(clear: tickIntBit)
    }

    /// Whether wrapping raises the exception, reading this clears COUNTFLAG
    public static var isInterruptEnabled: Bool {
        csr.load() & tickIntBit != 0
    }

    // MARK: Clock source

    /// The clock the counter runs from, reading this clears COUNTFLAG
    public static var clockSource: ClockSource {
        get { csr.load() & clkSourceBit != 0 ? .core : .external }

        set {
            switch newValue {
            case .core: modifyCSR(set: clkSourceBit)
            case .external: modifyCSR(clear: clkSourceBit)
            }
        }
    }

    // MARK: Reload and current value

    /// Sets the value the counter restarts from after reaching zero
    public static func setReload(_ value: UInt32) throws(Error) {
        try validate(reload: value)
        rvr.store(value)
    }

    /// The value the counter restarts from after reaching zero
    public static var reload: UInt32 {
        rvr.load() & maximumReload
    }

    /// The counter's current value, it counts down to zero, then reloads
    public static var current: UInt32 {
        cvr.load() & maximumReload
    }

    /// Resets the counter to zero, so the next wrap is a full `reload + 1`
    /// clocks away, clears COUNTFLAG
    public static func clearCurrent() {
        cvr.store(0)
    }

    /// Whether the counter has wrapped to zero since the control register was last read
    public static func hasWrapped() -> Bool {
        csr.load() & countFlagBit != 0
    }

    // MARK: Calibration

    public static var ticksPer10ms: UInt32 {
        calib.load() & tenmsMask
    }

    public static var isPrecise: Bool {
        calib.load() & skewBit == 0
    }

    public static var hasReferenceClock: Bool {
        calib.load() & noRefBit == 0
    }

    // MARK: Convenience

    ///
    /// Configures and starts the counter in one step, in the order the
    /// architecture requires: stop, set the reload, clear the current value, enable.
    ///
    /// - Throws: `Error.reloadOutOfRange`, in which case nothing was touched.
    ///
    public static func start(
        reload: UInt32,
        clockSource: ClockSource = .core,
        interrupt: Bool = true,
    ) throws(Error) {
        try validate(reload: reload)

        csr.store(0)  // stop before retiming, so no stale reload can fire
        rvr.store(reload)
        cvr.store(0)  // a write of any value clears the counter and COUNTFLAG
        csr.store(
            enableBit | (interrupt ? tickIntBit : 0) | (clockSource == .core ? clkSourceBit : 0)
        )
    }

    /// Stops the counter and disables the interrupt.
    public static func stop() {
        csr.store(0)
    }

    // MARK: Internal

    /// Counts `clocks` clocks once, from the processor clock, with the
    /// interrupt off, `hasWrapped()` reports completion.
    ///
    /// - Precondition - `2...maximumReload + 1` a run of one clock
    ///   has a reload of zero, which never wraps.
    static func countOnce(clocks: UInt32) {
        csr.store(0)
        rvr.store(clocks - 1)
        cvr.store(0)
        csr.store(enableBit | clkSourceBit)
    }
}
