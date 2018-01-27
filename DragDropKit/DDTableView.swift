//
//  DDTableView.swift
//  DragDropKit
//
//  Created by Jiar on 20/01/2018.
//  Copyright © 2018 Jiar. All rights reserved.
//

import UIKit

@objc public protocol DDTableViewDelegate: class {
    
    @objc optional func durationOGesturePress(_ tableView: DDTableView) -> CFTimeInterval
    
    @objc optional func tableView(_ tableView: DDTableView, beginMoveRowAt indexPath: IndexPath)
    
    @objc optional func durationOfMakeup(_ tableView: DDTableView) -> TimeInterval
    
    @objc optional func tableView(_ tableView: DDTableView, willMakeup snapShotView: UIView)
    
    @objc optional func tableView(_ tableView: DDTableView, didMakeup snapShotView: UIView)
    
    @objc optional func tableView(_ tableView: DDTableView, endMoveRowAt indexPath: IndexPath)
    
    @objc optional func durationOfTakeoff(_ tableView: DDTableView) -> TimeInterval
    
    @objc optional func tableView(_ tableView: DDTableView, willTakeoff snapShotView: UIView)
    
    @objc optional func tableView(_ tableView: DDTableView, didTakeoff snapShotView: UIView)
    
}

public class DDTableView: UITableView {
    
    enum InitMethod {
        case `default`
        case coder(NSCoder)
        case frame(CGRect, UITableViewStyle)
    }
    
    public convenience init() {
        self.init(.default)
    }
    
    public required convenience init(coder aDecoder: NSCoder) {
        self.init(.coder(aDecoder))
    }
    
    public override convenience init(frame: CGRect, style: UITableViewStyle) {
        self.init(.frame(frame, style))
    }
    
    private init(_ initMethod: InitMethod) {
        switch initMethod {
        case .default:
            super.init(frame: CGRect.zero, style: .plain)
        case let .coder(coder):
            super.init(coder: coder)!
        case let .frame(frame, style):
            super.init(frame: frame, style: style)
        }
        setup()
    }
    
    private var gestureRecognizer: UILongPressGestureRecognizer!
    private var centerDistancePoint: CGPoint?
    private var sourceIndexPath: IndexPath?
    private var lastIndexPath: IndexPath?
    private var snapShotView: UIView?
    private var edgeScrollTimer: CADisplayLink?
    
    open weak var ddDelegate: DDTableViewDelegate?
    open var durationOGesturePress: CFTimeInterval = 0.5 {
        didSet {
            if durationOGesturePress < 0.2 {
                durationOGesturePress = 0.2
            }
        }
    }
    open var durationOfMakeup: TimeInterval = 0.25
    open var durationOfTakeoff: TimeInterval = 0.25
    open var enableEdgeScroll: Bool = true
    open var edgeScrollRange: CGFloat = 0
    
    private func setup() {
        edgeScrollRange = bounds.height/8
        initGestureRecognizer()
    }
    
    private func initGestureRecognizer() {
        gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(gestureRecognizerAction(gesture:)))
        let duration: CFTimeInterval
        if let durationTime = ddDelegate?.durationOGesturePress?(self) {
            duration = durationTime
        } else {
            duration = durationOGesturePress
        }
        gestureRecognizer.minimumPressDuration = duration
        addGestureRecognizer(gestureRecognizer)
    }
    
    @objc private func gestureRecognizerAction(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            gestureBegan(gesture: gesture)
        case .changed:
            gestureChanged(gesture: gesture)
        case .ended, .cancelled, .failed:
            gestureOver(gesture: gesture)
        case .possible:
            break
        }
    }
    
    private func gestureBegan(gesture: UILongPressGestureRecognizer) {
        releaseValues()
        let location = gesture.location(in: gesture.view)
        guard let currentIndexPath = indexPathForRow(at: location), let cell = cellForRow(at: currentIndexPath) else {
            releaseValues()
            return
        }
        if let canMoveRow = dataSource?.tableView?(self, canMoveRowAt: currentIndexPath) {
            guard canMoveRow else {
                return
            }
        }
        let point = gesture.location(in: cell)
        centerDistancePoint = CGPoint(x: point.x-cell.frame.width/2, y: point.y-cell.frame.height/2)
        ddDelegate?.tableView?(self, beginMoveRowAt: currentIndexPath)
        sourceIndexPath = currentIndexPath
        lastIndexPath = currentIndexPath
        
        snapShotView = fetchSnapShotView(from: cell)
        guard let snapShotView = snapShotView else {
            releaseValues()
            return
        }
        if ddDelegate?.tableView?(self, willMakeup: snapShotView) == nil {
            makeupSnapShotView(with: snapShotView)
        }
        snapShotView.alpha = 0
        snapShotView.frame = cell.frame
        addSubview(snapShotView)
        
        startEdgeScroll()
        
        let duration: TimeInterval
        if let durationTime = ddDelegate?.durationOfMakeup?(self) {
            duration = durationTime
        } else {
            duration = durationOfMakeup
        }
        UIView.animate(withDuration: duration, animations: {
            if let _ = self.ddDelegate?.tableView?(self, didMakeup: snapShotView) {
                if snapShotView.alpha < 0.2 {
                    snapShotView.alpha = 0.2
                }
            } else {
                snapShotView.alpha = 0.98
                snapShotView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            }
            snapShotView.frame = cell.frame
            cell.alpha = 0
            cell.isHidden = true
        }, completion: { finished in
            cell.isHidden = true
        })
    }
    
    private func gestureChanged(gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: gesture.view)
        guard let currentIndexPath = indexPathForRow(at: location), let centerDistancePoint = centerDistancePoint, let sourceIndexPath = sourceIndexPath, let _ = lastIndexPath, let snapShotView = snapShotView else {
            return
        }
        snapShotView.center = CGPoint(x: location.x-centerDistancePoint.x, y: location.y-centerDistancePoint.y)
        guard currentIndexPath != sourceIndexPath else {
            return
        }
        if let canMoveRow = dataSource?.tableView?(self, canMoveRowAt: currentIndexPath) {
            guard canMoveRow else {
                return
            }
        }
        guard let _ = dataSource?.tableView?(self, moveRowAt: sourceIndexPath, to: currentIndexPath) else {
            print("must implementation the function: \"tableView(_:moveRowAt:to:)\" in UITableViewDataSource")
            return
        }
        moveRow(at: sourceIndexPath, to: currentIndexPath)
        lastIndexPath = sourceIndexPath
        self.sourceIndexPath = currentIndexPath
    }
    
    private func gestureOver(gesture: UILongPressGestureRecognizer) {
        stopEdgeScroll()
        
        var indexPath: IndexPath?
        if let currentIndexPath = indexPathForRow(at: gesture.location(in: gesture.view)) {
            indexPath = currentIndexPath
        } else if let lastIndexPath = lastIndexPath {
            indexPath = lastIndexPath
        }
        guard let currentIndexPath = indexPath, let _ = centerDistancePoint, let sourceIndexPath = sourceIndexPath, let cell = cellForRow(at: sourceIndexPath), let snapShotView = snapShotView else {
            releaseValues()
            return
        }
        ddDelegate?.tableView?(self, endMoveRowAt: currentIndexPath)
        
        if let _ = ddDelegate?.tableView?(self, willTakeoff: snapShotView) {
            if snapShotView.alpha < 0.2 {
                snapShotView.alpha = 0.2
            }
        }
        cell.alpha = 0
        
        let duration: TimeInterval
        if let durationTime = ddDelegate?.durationOfTakeoff?(self) {
            duration = durationTime
        } else {
            duration = durationOfTakeoff
        }
        UIView.animate(withDuration: duration, animations: {
            if self.ddDelegate?.tableView?(self, didTakeoff: snapShotView) == nil {
                snapShotView.transform = .identity
            }
            snapShotView.frame = cell.frame
            snapShotView.alpha = 0
            cell.alpha = 1
        }, completion: { finished in
            cell.isHidden = false
            self.releaseValues()
        })
    }
    
    private func releaseValues() {
        centerDistancePoint = nil
        sourceIndexPath = nil
        snapShotView?.removeFromSuperview()
        snapShotView = nil
    }
    
    private func fetchSnapShotView(from inputView: UIView) -> UIView? {
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        inputView.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let snapShotView = UIImageView(image: image)
        return snapShotView
    }
    
    private func makeupSnapShotView(with snapShotView: UIView) {
        snapShotView.layer.masksToBounds = false
        snapShotView.layer.shadowColor = UIColor.gray.cgColor
        snapShotView.layer.cornerRadius = 0
        snapShotView.layer.shadowOffset = CGSize(width: -2, height: 0)
        snapShotView.layer.shadowOpacity = 0.4
        snapShotView.layer.shadowRadius = 5
    }
    
    private func startEdgeScroll() {
        edgeScrollTimer = CADisplayLink(target: self, selector: #selector(processEdgeScroll))
        edgeScrollTimer?.add(to: RunLoop.main, forMode: .commonModes)
    }
    
    @objc private func processEdgeScroll(displaylink: CADisplayLink) {
        gestureChanged(gesture: gestureRecognizer)
        guard let snapShotView = snapShotView, let centerDistancePoint = centerDistancePoint else {
            return
        }
        let minOffsetY = contentOffset.y+edgeScrollRange
        let maxOffsetY = contentOffset.y+bounds.size.height-edgeScrollRange
        let touchPoint = snapShotView.center
        let location = gestureRecognizer.location(in: gestureRecognizer.view)
        let limit: CGFloat
        if #available(iOS 10.0, *) {
            limit = CGFloat(1 / (displaylink.targetTimestamp - displaylink.timestamp))
        } else {
            limit = 1
        }
        if touchPoint.y < edgeScrollRange {
            guard contentOffset.y-limit >= 0 else {
                snapShotView.center = CGPoint(x: location.x-centerDistancePoint.x, y: location.y-centerDistancePoint.y)
                return
            }
            snapShotView.center = CGPoint(x: snapShotView.center.x, y: snapShotView.center.y-limit)
            setContentOffset(CGPoint(x: contentOffset.x, y: contentOffset.y-limit), animated: false)
            return
        }
        if touchPoint.y > contentSize.height-edgeScrollRange {
            guard contentSize.height-bounds.size.height-contentOffset.y-limit >= 0 else {
                snapShotView.center = CGPoint(x: location.x-centerDistancePoint.x, y: location.y-centerDistancePoint.y)
                return
            }
            snapShotView.center = CGPoint(x: snapShotView.center.x, y: snapShotView.center.y+limit)
            setContentOffset(CGPoint(x: contentOffset.x, y: contentOffset.y+limit), animated: false)
            return
        }
        let maxMoveDistance: CGFloat = 10
        if touchPoint.y < minOffsetY {
            let moveDistance = (minOffsetY-touchPoint.y)/edgeScrollRange*maxMoveDistance
            setContentOffset(CGPoint(x: contentOffset.x, y: contentOffset.y-moveDistance), animated: false)
        } else if touchPoint.y > maxOffsetY {
            let moveDistance = (touchPoint.y-maxOffsetY)/edgeScrollRange*maxMoveDistance
            setContentOffset(CGPoint(x: contentOffset.x, y: contentOffset.y+moveDistance), animated: false)
        }
    }
    
    private func stopEdgeScroll() {
        edgeScrollTimer?.invalidate()
        edgeScrollTimer = nil
    }

}
