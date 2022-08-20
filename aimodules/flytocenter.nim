include wasmedge/exporter
import vmath



proc init() {.wasmexport.} = discard
proc allocMem(size: int32): pointer {.wasmexport.} = system.alloc(size)
proc deallocMem(address: pointer) {.wasmexport.} = system.dealloc(address)

proc update(id: int32, dt: float32) {.wasmexport.} = discard
