//
//  Extensions.swift
//  ChatApp
//
//  Created by Quan's Macbook on 18/05/2022.
//

import UIKit

extension UIView {
    public var width: CGFloat {
        return self.frame.size.width
    }
    public var height: CGFloat {
        return self.frame.size.height
    }
    public var top: CGFloat {
        return self.frame.origin.y
    }
    public var bottom: CGFloat {
        return height + top
    }
    public var left: CGFloat {
        return self.frame.origin.x
    }
    public var right: CGFloat {
        return left + width
    }
}
