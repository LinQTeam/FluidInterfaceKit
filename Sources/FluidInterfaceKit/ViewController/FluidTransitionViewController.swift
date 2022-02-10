import UIKit

/// Supports transition
/// compatible with ``FluidStackController``
open class FluidTransitionViewController: _fluid_WrapperViewController {

  public var addingTransition: AnyAddingTransition?
  public var removingTransition: AnyRemovingTransition?

  private var addingTransitionContext: AddingTransitionContext?
  private var removingTransitionContext: RemovingTransitionContext?

  public init(
    addingTransition: AnyAddingTransition?,
    removingTransition: AnyRemovingTransition?
  ) {

    self.addingTransition = addingTransition
    self.removingTransition = removingTransition

    super.init()
  }

  public init(
    bodyViewController: UIViewController,
    addingTransition: AnyAddingTransition?,
    removingTransition: AnyRemovingTransition?
  ) {

    self.addingTransition = addingTransition
    self.removingTransition = removingTransition
    super.init(bodyViewController: bodyViewController)
  }

  public init(
    view: UIView,
    addingTransition: AnyAddingTransition?,
    removingTransition: AnyRemovingTransition?
  ) {

    self.addingTransition = addingTransition
    self.removingTransition = removingTransition
    super.init(view: view)
  }

  /// From ``FluidStackController``
  func startAddingTransition(context: AddingTransitionContext) {

    guard let addingTransition = addingTransition else {
      AnyAddingTransition.noAnimation.startTransition(context: context)
      return
    }

    addingTransition.startTransition(
      context: context
    )

  }

  /// From ``FluidStackController``
  func startRemovingTransition(context: RemovingTransitionContext) {

    guard let removingTransition = removingTransition else {
      AnyRemovingTransition.noAnimation.startTransition(context: context)
      return
    }

    removingTransition.startTransition(context: context)
  }
  
  open override func didMove(toParent parent: UIViewController?) {    
    super.didMove(toParent: parent)
    
    assert({
      guard let parent = parent else {
        return true
      }
      return parent is FluidStackController
    }(), "Unsupported operation, \(self) was added into unsupported view controller. \(String(describing: parent))")
  }

  open override func viewDidAppear(_ animated: Bool) {

    super.viewDidAppear(animated)
    
    assert({
      guard let parent = parent else {
        return true
      }
      return parent is FluidStackController
    }(), "Unsupported operation, \(self) was added into unsupported view controller. \(String(describing: parent))")
    
  }
}