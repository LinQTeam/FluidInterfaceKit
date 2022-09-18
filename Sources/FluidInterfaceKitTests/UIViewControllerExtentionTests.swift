import Foundation
import XCTest

@testable import FluidInterfaceKit

@MainActor
final class UIViewControllerExtensionTests: XCTestCase {
  
  func testFluidStackControllers_including_self() {
    
    let stack = FluidStackController()
    
    let result = stack.fluidStackControllers()
    
    XCTAssert(result.contains(stack))
        
  }
  
}
