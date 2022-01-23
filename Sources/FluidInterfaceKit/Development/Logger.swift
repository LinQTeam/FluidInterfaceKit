
import os.log

enum Log {

  static func debug(_ log: OSLog, _ object: Any...) {
    os_log(.debug, log: log, "%@", object.map { "\($0)" }.joined(separator: " "))
  }
  
  static func error(_ log: OSLog, _ object: Any...) {
    os_log(.error, log: log, "%@", object.map { "\($0)" }.joined(separator: " "))
  }
  
  static func fault(_ log: OSLog, _ object: Any...) {
    os_log(.fault, log: log, "%@", object.map { "\($0)" }.joined(separator: " "))
  }

}

extension OSLog {

  @inline(__always)
  private static func makeOSLogInDebug(_ factory: () -> OSLog) -> OSLog {
#if DEBUG
    return factory()
#else
    return .disabled
#endif
  }

  static let stack: OSLog = makeOSLogInDebug { OSLog.init(subsystem: "FluidUIKit", category: "FluidStackController") }

  static let pip: OSLog = makeOSLogInDebug { OSLog.init(subsystem: "FluidUIKit", category: "PIP") }
}
