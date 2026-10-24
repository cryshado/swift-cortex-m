# swift-cortex-m

Building blocks for Arm® Cortex®-M development in Embedded Swift.

- **[CortexMRuntime](Sources/CortexMRuntime)** - startup code and a minimal runtime.
- **[CortexMCore](Sources/CortexMCore)** - low-level access to core peripherals.
- **[CortexMSetup](Plugins/CortexMSetup)** - a SwiftPM setup plugin for your device.

## Example Usage

1. Install [Arm Toolchain for Embedded](https://support.arm.com/tools-and-software/arm-toolchain-for-embedded)
and add it to your environment.

Go to the [arm/arm-toolchain](https://github.com/arm/arm-toolchain) repository and download a prebuilt release for your system
or build it from source, then set the `ARM_TOOLCHAIN_FOR_EMBEDDED` environment variable to point to it
(for example, `ARM_TOOLCHAIN_FOR_EMBEDDED=/Users/user/toolchains/ATfE-22.1.0-Darwin-universal`).

2. Make sure you are using a Swift toolchain installed via [swiftly](https://github.com/swiftlang/swiftly).

3. Create an empty directory for the new project, `cd` into it, and initialize the package:
```bash
mkdir swift-cortex-m-example
cd swift-cortex-m-example
swift package init --disable-swift-testing --type executable --name App
```

4. Replace the `let package = ...` section in `Package.swift` with the following:
```swift
let package = Package(
    name: "swift-cortex-m-example",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/cryshado/swift-cortex-m", branch: "main"),
        .package(url: "https://github.com/cryshado/swift-stm32", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "CortexMCore", package: "swift-cortex-m"),
                .product(name: "CortexMRuntime", package: "swift-cortex-m"),
                .product(name: "STM32G431", package: "swift-stm32"),
            ],
        )
    ],
)
```

5. Replace the code in `Sources/App/App.swift`. We'll blink an LED by writing registers directly:
```swift
import CortexMCore
import CortexMRuntime
import STM32G431

@main
struct App {
    static func main() {
        let delay = SysTick.Delay(coreClockHz: 16_000_000)

        rcc.ahb2enr.modify { $0.gpioben = .Enabled }
        gpiob.moder.modify { $0.moder_field8 = .Output }

        while true {
            gpiob.odr.modify { $0.raw.odr_field8 ^= 1 } // toggle PB8
            delay.wait(milliseconds: 250)
        }
    }
}
```

6. Set up the project configuration using the `CortexMSetup` plugin:
```bash
SWIFT_STM32_DEVICES=STM32G431 swift package \
    --allow-writing-to-package-directory cortex-m-setup \
    --device STM32G431
```

7. Edit the generated `memory.x` for your target MCU (STM32G431 in this example):
```
MEMORY
{
    FLASH : ORIGIN = 0x08000000, LENGTH = 128K
    RAM   : ORIGIN = 0x20000000, LENGTH = 32K
}

_heap_size  = 0;
_stack_size = 0x400;
```

8. Build the project with `make` (the first build takes a while):
```bash
SWIFT_STM32_DEVICES=STM32G431 make all
```

9. Flash `.build/release/App.bin` to your board and enjoy!

## HardFault Backtraces

The generated `toolset.json` defines `SCMR_DEBUG_HARDFAULT_UNWIND`, which lets
a debugger show a backtrace from `HardFault_Handler` back to the faulting code.
It costs a few dozen bytes of flash. To turn it off, remove
`"-DSCMR_DEBUG_HARDFAULT_UNWIND"` from `toolset.json`.

## License

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.

## Disclaimer

This project is an independently developed open-source package and is not affiliated with, sponsored by, or endorsed by STMicroelectronics, Apple Inc or Arm Limited. STM32 is a trademark of STMicroelectronics International NV or its affiliates. Swift is a trademark of Apple Inc., registered in the U.S. and other countries and regions. Arm and Cortex are registered trademarks of Arm Limited (or its subsidiaries) in the US and/or elsewhere.

## Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in the work by you, as defined in the Apache-2.0 license, shall be dual licensed as above, without any additional terms or conditions.
