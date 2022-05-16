var initProcs: seq[proc()]

proc addResourceProc*(p: proc()) =
  initProcs.add p

proc invokeResourceProcs*() =
  for p in initProcs:
    p()
