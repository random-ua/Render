//
//  ReusableViewsPool.swift
//  Render
//
//  Created by Alex Usbergo on 02/05/16.
//
//  Copyright (c) 2016 Alex Usbergo.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

protocol ComponentViewWithReusePoolViewType: ComponentViewType {

  /// The reusable pool associated to this component view.
  var reusePool: ComponentViewReusePool? { get }

}

class ComponentViewReusePool {

  /// The dictionary that stores the reusable views.
  fileprivate var pool = [String: [UIView]]()

  /// Returns a view with the given reusable identifier (if available) and removes
  /// it from the pool.
  func pop(_ identifier: String) -> UIView? {
    guard var array = self.pool[identifier] else { return nil }
    let view = array.popLast()
    self.pool[identifier] = array
    return view
  }

  /// Adds a view to the reuse pool.
  func push(_ identifier: String, view: UIView) {
    if identifier == String(describing: type(of: view)) {
      return
    }
    Reset.resetTargets(view)
    var array = self.pool[identifier] ?? [UIView]()
    array.append(view)
    self.pool[identifier] = array
  }

  /// Removes all the views from the reuse pool.
  func drain() {
    self.pool = [String: [UIView]]()
  }

}
