import UIKit
import GeometryKit
import ResultBuilderKit

extension AnyAddingTransition {

  public static func contextualExpanding(
    from entrypointView: UIView,
    entrypointMirrorViewProvider: AnyMirrorViewProvider,
    hidingViews: [UIView]
  ) -> Self {

    return .init { (context: AddingTransitionContext) in
      
      let entrypointSnapshotView = entrypointMirrorViewProvider.view()

      // FIXME: tmp impl
      BatchApplier(hidingViews).setInvisible(true)

      context.addCompletionEventHandler { event in
        BatchApplier(hidingViews).setInvisible(false)
      }

      let maskView = UIView()
      maskView.backgroundColor = .black

      if context.contentView.backgroundColor == nil {
        context.contentView.backgroundColor = .clear
      }

      if !Fluid.hasAnimations(view: context.toViewController.view) {

        maskView.frame = context.toViewController.view.bounds

        if #available(iOS 13.0, *) {
          maskView.layer.cornerCurve = .continuous
        } else {
          // Fallback on earlier versions
        }
        maskView.layer.cornerRadius = 24

        context.toViewController.view.mask = maskView

        context.addCompletionEventHandler { _ in
          entrypointSnapshotView.removeFromSuperview()
        }

        context.contentView.addSubview(entrypointSnapshotView)
        entrypointSnapshotView.frame = context.frameInContentView(for: entrypointView)

        let fromFrame = CGRect(
          origin: context.frameInContentView(for: entrypointView).origin,
          size: Geometry.sizeThatAspectFill(
            aspectRatio: context.toViewController.view.bounds.size,
            minimumSize: entrypointView.bounds.size
          )
        )

        /// make initial state for displaying view
        let translation = Geometry.centerAndScale(from: context.contentView.bounds, to: fromFrame)

        context.toViewController.view.transform = .init(scaleX: translation.scale.x, y: translation.scale.y)
        context.toViewController.view.center = translation.center
        context.toViewController.view.alpha = 0.2

        // fix visually height against transforming
        maskView.frame.size.height = entrypointView.bounds.height / translation.scale.y

      }

      let translationAnimators = Fluid.makePropertyAnimatorsForTranformUsingCenter(
        view: context.toViewController.view,
        duration: 0.7,
        position: .center(of: context.toViewController.view.bounds),
        scale: .init(x: 1, y: 1),
        velocityForTranslation: .zero,
        velocityForScaling: 0
      )

      let translationForSnapshot = Geometry.centerAndScale(
        from: entrypointSnapshotView.frame,
        to: .init(origin: .zero, size: entrypointSnapshotView.frame.size)
      )

      let snapshotTranslationAnimators = Fluid.makePropertyAnimatorsForTranformUsingCenter(
        view: entrypointSnapshotView,
        duration: 0.7,
        position: .custom(translationForSnapshot.center),
        scale: translationForSnapshot.scale,
        velocityForTranslation: .zero,
        velocityForScaling: 0
      )

      let maskAnimator = UIViewPropertyAnimator(duration: 0.6, dampingRatio: 1) {
        maskView.transform = .identity
        maskView.frame = context.toViewController.view.bounds
      }

      maskAnimator.addAnimations({
        maskView.layer.cornerRadius = 0
      })

      maskAnimator.addCompletion { _ in
        context.toViewController.view.mask = nil
      }

      let crossfadeAnimator = UIViewPropertyAnimator(duration: 0.3, dampingRatio: 1) {
        context.toViewController.view.alpha = 1
        entrypointSnapshotView.alpha = 0
        context.contentView.backgroundColor = .init(white: 0, alpha: 0.6)
      }

      Fluid.startPropertyAnimators(
        buildArray {
          translationAnimators
          maskAnimator
          snapshotTranslationAnimators
          crossfadeAnimator
        },
        completion: {
          context.notifyAnimationCompleted()
        }
      )

    }
  }
}