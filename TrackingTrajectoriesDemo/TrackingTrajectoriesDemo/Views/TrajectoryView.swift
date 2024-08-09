//
//  TrajectoryView.swift
//  TrackingTrajectoriesDemo
//
//  Created by USER on 06.08.2024.
//

import UIKit
import Vision

class TrajectoryView: UIView, AnimatedTransitioning {
    var fullTrajectory = UIBezierPath()
    var duration = 0.0
    var points: [VNPoint] = [] {
        didSet {
            updatePathLayer()
        }
    }
    var regionOfInterest: CGRect? {
        didSet {
            setupRegionOfInterestView()
        }
    }
    let regionOfInterestView = UIView()
    
    private let pathLayer = CAShapeLayer()
    private let blurLayer = CAShapeLayer()
    private let shadowLayer = CAShapeLayer()
    
    private var distanceWithCurrentTrajectory: CGFloat = 0
    private var isTrajectoryMovingForward: Bool {
        // Check if the trajectory is moving from left to right
        if let firstPoint = points.first, let lastPoint = points.last {
            return lastPoint.location.x > firstPoint.location.x
        }
        return false
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }
    
    func setupRegionOfInterestView() {
        addSubview(regionOfInterestView)
        regionOfInterestView.translatesAutoresizingMaskIntoConstraints = false
        guard let regionOfInterest else { return }
        
        regionOfInterestView.leadingAnchor.constraint(equalTo: self.leadingAnchor,
                                                      constant: self.frame.width * regionOfInterest.minX).isActive = true
        regionOfInterestView.bottomAnchor.constraint(equalTo: self.bottomAnchor,
                                                     constant: -(self.frame.height * regionOfInterest.minY)).isActive = true
        regionOfInterestView.trailingAnchor.constraint(equalTo: self.trailingAnchor,
                                                       constant: -(self.frame.width * (1 - regionOfInterest.maxX))).isActive = true
        regionOfInterestView.topAnchor.constraint(equalTo: self.topAnchor, constant:
                                                    self.frame.height * (1 - regionOfInterest.maxY)).isActive = true
       
        regionOfInterestView.backgroundColor = .white
        regionOfInterestView.alpha = 0.3
    }
    
    func resetPath() {
        distanceWithCurrentTrajectory = 0
        fullTrajectory.removeAllPoints()
        pathLayer.path = fullTrajectory.cgPath
        blurLayer.path = fullTrajectory.cgPath
        shadowLayer.path = fullTrajectory.cgPath
    }
    
    func addPath(_ path: CGPath) {
        fullTrajectory.cgPath = path
        pathLayer.lineWidth = 2
        pathLayer.path = fullTrajectory.cgPath
        shadowLayer.lineWidth = 4
        shadowLayer.path = fullTrajectory.cgPath
    }
    
    private func setupLayer() {
        shadowLayer.lineWidth = 12.0
        shadowLayer.lineCap = .round
        shadowLayer.fillColor = UIColor.clear.cgColor
        shadowLayer.strokeColor = #colorLiteral(red: 0.9882352941, green: 0.4666666667, blue: 0, alpha: 0.4519210188).cgColor
        layer.addSublayer(shadowLayer)
        blurLayer.lineWidth = 8.0
        blurLayer.lineCap = .round
        blurLayer.fillColor = UIColor.clear.cgColor
        blurLayer.strokeColor = #colorLiteral(red: 0.9960784314, green: 0.737254902, blue: 0, alpha: 0.597468964).cgColor
        layer.addSublayer(blurLayer)
        pathLayer.lineWidth = 4.0
        pathLayer.lineCap = .round
        pathLayer.fillColor = UIColor.clear.cgColor
        pathLayer.strokeColor = #colorLiteral(red: 0.9960784314, green: 0.737254902, blue: 0, alpha: 0.7512574914).cgColor
        layer.addSublayer(pathLayer)
    }
    
    private func updatePathLayer() {
        let trajectory = UIBezierPath()
        guard let startingPoint = points.first else {
            return
        }
        trajectory.move(to: startingPoint.location)
        for point in points.dropFirst() {
            trajectory.addLine(to: point.location)
        }
        let flipVertical = CGAffineTransform.verticalFlip
        trajectory.apply(flipVertical)
        
        trajectory.apply(CGAffineTransform(scaleX: (regionOfInterest?.width ?? 1) * bounds.width, y: (regionOfInterest?.height ?? 1) * bounds.height))
        trajectory.apply(CGAffineTransform(translationX: (regionOfInterest?.minX ?? 0) * bounds.width, y: (1 - (regionOfInterest?.maxY ?? 0)) * bounds.height))

        fullTrajectory = trajectory
//        fullTrajectory.append(trajectory)
        shadowLayer.path = fullTrajectory.cgPath
        blurLayer.path = fullTrajectory.cgPath
        pathLayer.path = fullTrajectory.cgPath

    }
}
struct GameConstants {
    static let maxThrows = 8
    static let newGameTimer = 5
    static let boardLength = 1.22
    static let trajectoryLength = 15
    static let maxPoseObservations = 45
    static let noObservationFrameLimit = 20
    static let maxDistanceWithCurrentTrajectory: CGFloat = 250
    static let maxTrajectoryInFlightPoseObservations = 10
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return hypot(x - point.x, y - point.y)
    }
    
    func angleFromHorizontal(to point: CGPoint) -> Double {
        let angle = atan2(point.y - y, point.x - x)
        let deg = abs(angle * (180.0 / CGFloat.pi))
        return Double(round(100 * deg) / 100)
    }
}
