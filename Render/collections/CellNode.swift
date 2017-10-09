import Foundation
import UIKit

// MARK: - Cell protocol

public protocol CellNodeType: class  {
  /// The cell contentview.
  var contentView: UIView { get }
  /// The associated UITableView or UICollectionView.
  weak var listView: UIView? { get set }
  /// The indexpath for this cell.
  var currentIndexPath: IndexPath { get set }
  /// The component view wrapped by this cell.
  var componentView: AnyComponentView? { get set }
  /// Calls render on the underlying component view. See: 'render(in:options)' in ComponentView.
  func update(options: [RenderOption])
  /// Invoked whenever the component is being laid out.
 func onLayout(duration: TimeInterval, component: AnyComponentView, size: CGSize)
  /// Mount the component passed as argument in the cell.
  func mountComponentIfNecessary(isStateful: Bool,
                                 _ component: @autoclosure () -> AnyComponentView)
  /// Returns the bounding rect for the component.
  func referenceSize(_ component: AnyComponentView?) -> CGSize
}

extension CellNodeType where Self: UIView {
  public func mountComponentIfNecessary(isStateful: Bool = true,
                                        _ component: @autoclosure () -> AnyComponentView){
    componentView?.referenceSize = referenceSize
    guard componentView == nil || isStateful else {
      return
    }
    componentView = component()
    componentView?.referenceSize = referenceSize
    for subview in contentView.subviews {
      subview.removeFromSuperview()
    }
    if let componentView = componentView as? UIView {
      contentView.addSubview(componentView)
    }
  }

  /// Forward the invokation to update to the owned component view.
  public func update(options: [RenderOption] = []) {
    if let tableViewCell = self as? UITableViewCell {
      tableViewCell.selectionStyle = .none
    }
    componentView?.update(options: options)
  }

  func commonOnLayout(duration: TimeInterval) {
    guard let component = self.componentView, let view = self.componentView as? UIView else {
      return
    }
    contentView.frame.size = component.rootView.bounds.size
    view.center = contentView.center
    backgroundColor = component.rootView.backgroundColor
    contentView.backgroundColor = backgroundColor
  }

  func commonSizeThatFits(_ size: CGSize) -> CGSize {
    return componentView?.sizeThatFits(size) ?? CGSize.zero
  }

  var commonIntrinsicContentSize: CGSize {
    return componentView?.sizeThatFits(CGSize.undefined) ?? CGSize.zero
  }

  public func referenceSize(_ component: AnyComponentView?) -> CGSize {
    let container = listView ?? superview
    return CGSize(width: container?.bounds.size.width ?? UIScreen.main.bounds.size.width,
                  height: CGFloat.max)
  }
}

extension CellNodeType where Self: UITableViewCell {
  /// Called whenever the component finished to be rendered and updated its size.
  public func onLayout(duration: TimeInterval, component: AnyComponentView, size: CGSize) {
    guard component === componentView, let table = listView as? UITableView else {
      print("No table or component available for this cell.")
      return
    }
    commonOnLayout(duration: duration)
    guard let indexPath = table.indexPath(for: self),
          table.rectForRow(at: indexPath).height != component.bounds.size.height else {
      return
    }
    UIView.performWithoutAnimation {
      table.reloadRows(at: [indexPath], with: .none)
    }
  }
}

extension CellNodeType where Self: UICollectionViewCell {
  /// Called whenever the component finished to be rendered and updated its size.
  public func onLayout(duration: TimeInterval, component: AnyComponentView, size: CGSize) {
    guard component === componentView, let collectionView = listView as? UICollectionView else {
        print("No table or component available for this cell.")
        return
    }
    commonOnLayout(duration: duration)
    guard let indexPath = collectionView.indexPath(for: self),
          bounds.size.height != component.bounds.size.height else {
        return
    }
    UIView.performWithoutAnimation {
      collectionView.reloadItems(at: [indexPath])
    }
  }
}

// MARK: - UITableViewCell

/// Wraps a component in a UITableViewCell.
open class TableCellNode: UITableViewCell, CellNodeType  {
  public weak var listView: UIView?
  public var currentIndexPath = IndexPath(row: 0, section: 0)
  /// The component view wrapped by this cell.
  /// Internal use only. Use 'mountComponentIfNecessary' to add a component to this cell.
  public var componentView: AnyComponentView?

  /// Initializes a table cell with a style and a reuse identifier and returns it to the caller.
  public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  /// Asks the control to calculate and return the size that best fits the specified size.
  open override func sizeThatFits(_ size: CGSize) -> CGSize {
    return commonSizeThatFits(size)
  }

  /// The natural size for the receiving view, considering only properties of the view itself.
  open override var intrinsicContentSize: CGSize {
    return commonIntrinsicContentSize
  }
}

// MARK: - UICollectionViewCell

/// Wraps a component in a UICollectionViewCell.
open class CollectionNodeCell: UICollectionViewCell, CellNodeType {
  public weak var listView: UIView?
  public var currentIndexPath = IndexPath(item: 0, section: 0)
  /// The component view wrapped by this cell.
  /// Internal use only. Use 'mountComponentIfNecessary' to add a component to this cell.
  public var componentView: AnyComponentView?

  /// Asks the control to calculate and return the size that best fits the specified size.
  open override func sizeThatFits(_ size: CGSize) -> CGSize {
    return componentView?.bounds.size ?? CGSize.zero
  }

  /// The natural size for the receiving view, considering only properties of the view itself.
  open override var intrinsicContentSize: CGSize {
    return componentView?.bounds.size ?? CGSize.zero
  }
}

//MARK: - Extensions

extension UICollectionView {
  ///  Refreshes the component at the given index path.
  public func update(at indexPath: IndexPath) {
    performBatchUpdates({ self.reloadItems(at: [indexPath]) }, completion: nil)
  }

  /// Re-renders all the compoents currently visible on screen.
  /// Call this method whenever the collecrion view changes its bounds/size.
  public func updateVisibleComponents() {
    visibleCells
      .flatMap { cell in cell as? CellNodeType }
      .forEach { cell in cell.update(options: []) }
  }
}
