import GeometryKit
import ResultBuilderKit
import UIKit
import FluidPortal

extension AnyRemovingTransition {

  public static func contextual(
    destinationComponent: ContextualTransitionSourceComponentType
  ) -> Self {
    
    return .init { context in
      
      let sourceView = context.fromViewController.view!
      
      AnyRemovingInteraction.Contextual.runEnclosing(
        transitionContext: context,
        disclosedView: sourceView,
        destinationComponent: destinationComponent,
        gestureVelocity: .zero
      )
      
    }

  }

}

extension AnyRemovingInteraction {
  public enum Contextual {
        
    // TODO: naming
    @MainActor
    public static func runEnclosing(
      transitionContext: RemovingTransitionContext,
      disclosedView: UIView,
      destinationComponent: ContextualTransitionSourceComponentType,
      gestureVelocity: CGPoint?
    ) {
      
      let draggingView = disclosedView
                 
      let maskView = UIView()
      maskView.backgroundColor = .black
      maskView.frame = transitionContext.fromViewController.view.bounds
      
      let fromViewMirror = AnyMirrorViewProvider.snapshot(
        caches: true,
        viewProvider: { transitionContext.fromViewController.view! }
      ).view()
                  
      fromViewMirror.mask = maskView
      fromViewMirror.alpha = 1
      fromViewMirror.frame = transitionContext.fromViewController.view.frame
                        
      let entrypointMirrorView = AnyMirrorViewProvider.portal(
        view: destinationComponent.contentView,
        hidesSourceOnUsing: true
      ).view()
      
      /**
       Repareting view is a temporary view that displays animated views.
       For solving z-index problem that clips the animated views.
       hosted by the entry point view
       with this, animations runs correctly including on scroll view.
       */
      let reparentingView = destinationComponent.requestReparentView()
      
      let displayingSubscription = transitionContext.requestDisplayOnTop(.view(reparentingView))

      // layering
      do {
        reparentingView.addSubview(entrypointMirrorView)
        reparentingView.addSubview(fromViewMirror)
      }
        
      // places entrypoint mirror view in the current moving view to make cross-fade
      do {
        let translation = Geometry.centerAndScale(
          from: entrypointMirrorView.frame,
          to: Geometry.rectThatAspectFit(aspectRatio: entrypointMirrorView.frame.size, boundingRect: transitionContext.fromViewController.view.frame)
        )
              
        entrypointMirrorView.transform = .init(scaleX: translation.scale.x, y: translation.scale.y)
        entrypointMirrorView.center = translation.center
        entrypointMirrorView.alpha = 0
      }
                
      transitionContext.fromViewController.view.isHidden = true
      
      transitionContext.addCompletionEventHandler { [weak transitionContext] _ in
        transitionContext?.fromViewController.view.isHidden = false
      }

      // setup housekeeping
      transitionContext.addCompletionEventHandler { _ in
        reparentingView.removeFromSuperview()
        entrypointMirrorView.removeFromSuperview()
        fromViewMirror.removeFromSuperview()
        displayingSubscription.dispose()
      }
      
      let movingDuration: TimeInterval = 0.75
                        
      Fluid.startPropertyAnimators(
        buildArray(elementType: UIViewPropertyAnimator.self) {
          
          // displaying view moving
          do {
                        
            let translation = Geometry.centerAndScale(
              from: fromViewMirror.frame,
              to: CGRect(
                origin: transitionContext.frameInContentView(for: destinationComponent.contentView).origin,
                size: Geometry.sizeThatAspectFill(
                  aspectRatio: fromViewMirror.bounds.size,
                  minimumSize: destinationComponent.contentView.bounds.size
                )
              )
            )
            
            let velocityForAnimation: CGVector = {
              
              guard let gestureVelocity = gestureVelocity else {
                return .zero
              }
              
              let targetCenter = translation.center
              let delta = CGPoint(
                x: targetCenter.x - draggingView.center.x,
                y: targetCenter.y - draggingView.center.y
              )
              
              var velocity = CGVector.init(
                dx: gestureVelocity.x / delta.x,
                dy: gestureVelocity.y / delta.y
              )
              
              if velocity.dx.isNaN {
                velocity.dx = 0
              }
              
              if velocity.dy.isNaN {
                velocity.dy = 0
              }
              
              return velocity
              
            }()
            
            Fluid.makePropertyAnimatorsForTranformUsingCenter(
              view: fromViewMirror,
              duration: movingDuration,
              position: .custom(translation.center),
              scale: translation.scale,
              velocityForTranslation: velocityForAnimation,
              velocityForScaling: min(10, max(8, velocityForAnimation.magnitude))
            )
            
            UIViewPropertyAnimator(duration: 0.6, dampingRatio: 1) {
              transitionContext.contentView.backgroundColor = .clear
            };
            
            // mask
            UIViewPropertyAnimator(duration: 0.6, dampingRatio: 1) {
              maskView.frame = transitionContext.fromViewController.view.bounds
              maskView.frame.size.height = destinationComponent.contentView.bounds.height / translation.scale.y
              maskView.layer.cornerRadius = 36
              if #available(iOS 13.0, *) {
                maskView.layer.cornerCurve = .continuous
              } else {
                // Fallback on earlier versions
              }
            }
          }
          
          // entrypoint moving
          do {
            
            let translation = Geometry.centerAndScale(
              from: entrypointMirrorView.frameAsIdentity,
              to: transitionContext.frameInContentView(for: destinationComponent.contentView)
            )
            
            let velocityForAnimation: CGVector = {
              
              guard let gestureVelocity = gestureVelocity else {
                return .zero
              }
              
              let targetCenter = translation.center
              let delta = CGPoint(
                x: targetCenter.x - entrypointMirrorView.center.x,
                y: targetCenter.y - entrypointMirrorView.center.y
              )
              
              var velocity = CGVector.init(
                dx: gestureVelocity.x / delta.x,
                dy: gestureVelocity.y / delta.y
              )
              
              if velocity.dx.isNaN {
                velocity.dx = 0
              }
              
              if velocity.dy.isNaN {
                velocity.dy = 0
              }
              
              return velocity
              
            }()
                             
            Fluid.makePropertyAnimatorsForTranformUsingCenter(
              view: entrypointMirrorView,
              duration: movingDuration,
              position: .custom(translation.center),
              scale: translation.scale,
              velocityForTranslation: velocityForAnimation,
              velocityForScaling: min(10, max(8, velocityForAnimation.magnitude))
            );
                       
          }
           
          // cross-fade content
          do {
            UIViewPropertyAnimator(duration: movingDuration, dampingRatio: 1) {
              fromViewMirror.alpha = 0
              entrypointMirrorView.alpha = 1
            }
          }
                
        },
        completion: {
          transitionContext.notifyAnimationCompleted()
        }
      )
    }
    
    // TODO: naming
    @MainActor
    public static func runGettingTogether(
      transitionContext: RemovingTransitionContext,
      disclosedView: UIView,
      destinationComponent: ContextualTransitionSourceComponentType,
      gestureVelocity: CGPoint?
    ) {
      
      let draggingView = disclosedView
      
      let interpolationView = AnyMirrorViewProvider.portal(
        view: destinationComponent.contentView,
        hidesSourceOnUsing: true
      ).view()

      var targetRect = Geometry.rectThatAspectFit(
        aspectRatio: draggingView.bounds.size,
        boundingRect: transitionContext.frameInContentView(for: destinationComponent.contentView)
      )

      targetRect = targetRect.insetBy(
        dx: targetRect.width / 3,
        dy: targetRect.height / 3
      )

      let translation = Geometry.centerAndScale(
        from: draggingView.bounds,
        to: targetRect
      )

      let velocityForAnimation: CGVector = {
        
        guard let gestureVelocity = gestureVelocity else {
          return .zero
        }

        let targetCenter = translation.center
        let delta = CGPoint(
          x: targetCenter.x - draggingView.center.x,
          y: targetCenter.y - draggingView.center.y
        )

        let velocity = CGVector.init(
          dx: gestureVelocity.x / delta.x,
          dy: gestureVelocity.y / delta.y
        )

        return velocity

      }()

      let velocityForScaling: CGFloat = {

        //                    let gestureVelocity = gesture.velocity(in: gesture.view!)

        // TODO: calculate dynamic velocity
        // set greater than 0, throwing animation would be more clear. like springboard
        return 6

      }()

      var animators: [UIViewPropertyAnimator] = []

      let translationAnimators = Fluid.makePropertyAnimatorsForTranformUsingCenter(
        view: draggingView,
        duration: 0.85,
        position: .custom(translation.center),
        scale: translation.scale,
        velocityForTranslation: velocityForAnimation,
        velocityForScaling: velocityForScaling  //sqrt(pow(velocityForAnimation.dx, 2) + pow(velocityForAnimation.dy, 2))
      )

      let backgroundAnimator = UIViewPropertyAnimator(duration: 0.6, dampingRatio: 1) {
        transitionContext.contentView.backgroundColor = .clear
      }

      animators += translationAnimators + [backgroundAnimator]

      /// handling interpolation view
      do {
        interpolationView.center = .init(
          x: draggingView.frame.minX,
          y: draggingView.frame.minY
        )
        interpolationView.transform = .init(scaleX: 0.5, y: 0.5)

        transitionContext.contentView.addSubview(interpolationView)

        let interpolationViewAnimators =
          Fluid.makePropertyAnimatorsForTranformUsingCenter(
            view: interpolationView,
            duration: 0.85,
            position: .custom(translation.center),
            scale: .init(x: 1, y: 1),
            velocityForTranslation: velocityForAnimation,
            velocityForScaling: velocityForScaling
          )

        let interpolationViewStyleAnimator = UIViewPropertyAnimator(
          duration: 0.85,
          dampingRatio: 1
        ) {
          interpolationView.alpha = 1
        }

        animators += interpolationViewAnimators + [interpolationViewStyleAnimator]
      }

      Fluid.startPropertyAnimators(animators) {
        transitionContext.notifyAnimationCompleted()
      }
      
    }
  }
}