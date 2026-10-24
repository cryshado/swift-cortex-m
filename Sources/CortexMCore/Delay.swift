// Delay.swift

extension SysTick {
    //
    /// Blocking delays timed by SysTick itself. While waiting it owns SysTick,
    /// the reload, the current value and the enable bit are rewritten, the
    /// interrupt is disabled, the processor clock is selected, and the counter
    /// is left stopped afterwards.
    ///
    public struct Delay {
        /// The processor clock, which SysTick counts
        public let coreClockHz: UInt32

        public init(coreClockHz: UInt32) {
            self.coreClockHz = coreClockHz
        }

        public func wait(microseconds: UInt32) {
            wait(clocks: UInt64(microseconds) * UInt64(coreClockHz) / 1_000_000)
        }

        public func wait(milliseconds: UInt32) {
            wait(clocks: UInt64(milliseconds) * UInt64(coreClockHz) / 1_000)
        }

        /// Counts `clocks` in runs of at most 2^24, the most the counter holds.
        /// A final run of a single clock is skipped: a reload of zero never
        /// wraps, and one clock is below the noise of restarting the counter
        private func wait(clocks: UInt64) {
            var remaining = clocks

            while remaining > 1 {
                let run = UInt32(min(remaining, UInt64(SysTick.maximumReload) + 1))

                SysTick.countOnce(clocks: run)
                while !SysTick.hasWrapped() {}

                remaining -= UInt64(run)
            }

            SysTick.stop()
        }
    }
}
