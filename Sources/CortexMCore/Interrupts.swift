// Interrupts.swift

import CCortexMCore

/// Data Synchronization Barrier (`dsb`)
@inline(__always)
public func dataSynchronizationBarrier() {
    cortex_m_dsb()
}

/// Instruction Synchronization Barrier (`isb`)
@inline(__always)
public func instructionSynchronizationBarrier() {
    cortex_m_isb()
}

/// Sleep until an interrupt or event arrives (`wfi`)
@inline(__always)
public func waitForInterrupt() {
    cortex_m_wfi()
}

/// Unmask interrupts (`cpsie i`)
@inline(__always)
public func enableInterrupts() {
    cortex_m_enable_interrupts()
}

/// Mask interrupts (`cpsid i`)
@inline(__always)
public func disableInterrupts() {
    cortex_m_disable_interrupts()
}

/// Runs `body` with interrupts masked, restoring the previous PRIMASK
@inline(__always)
public func withInterruptsDisabled<T, E: Error>(
    _ body: () throws(E) -> T
) throws(E) -> T {
    let primask = cortex_m_primask()
    cortex_m_disable_interrupts()
    defer { cortex_m_restore_primask(primask) }

    return try body()
}
