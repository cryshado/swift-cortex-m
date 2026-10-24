// Runtime.swift

import CCortexMRuntime

public typealias ExceptionFrame = SCMRExceptionFrame

@inline(__always)
public func heapStart() -> UInt {
    UInt(bitPattern: scmr_heap_start())
}

@inline(__always)
public func heapEnd() -> UInt {
    UInt(bitPattern: scmr_heap_end())
}

@inline(__always)
public func stackStart() -> UInt {
    UInt(bitPattern: scmr_stack_start())
}

@inline(__always)
public func stackEnd() -> UInt {
    UInt(bitPattern: scmr_stack_end())
}
