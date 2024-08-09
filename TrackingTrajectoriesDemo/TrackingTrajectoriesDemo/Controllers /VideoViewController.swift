//
//  VideoViewController.swift
//  TrackingTrajectoriesDemo
//
//  Created by USER on 02.08.2024.
//

import UIKit
import AVFoundation
import Vision


class VideoViewController: UIViewController {
    private let videoManager = VideoManager.shared
    private var videoRenderView: VideoRenderView!
    private var playerItemOutput: AVPlayerItemVideoOutput?
    private var displayLink: CADisplayLink?
    private let videoFileReadingQueue = DispatchQueue(label:"VideoFileReading", qos: .userInteractive)
    private var videoFileBufferOrientation = CGImagePropertyOrientation.up
    private var videoFileFrameDuration = CMTime.invalid
    
    private lazy var request: VNDetectTrajectoriesRequest = {
        return VNDetectTrajectoriesRequest(frameAnalysisSpacing: .zero,
                                           trajectoryLength: 15,
                                           completionHandler: trajectoryRequestCompletionHandler)
    }()
    
    private let trajectoryView = TrajectoryView()
    private let regionOfInterest = CGRect(x: 0.3, y: 0.25, width: 0.5, height: 0.5)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .blue
        
        if let recordedVideo = videoManager.videoAsset {
            startReadingRecordedVideoAsset(asset: recordedVideo)
        } else {
            
        }
        
        view.addSubview(trajectoryView)
        trajectoryView.frame = view.frame
        trajectoryView.regionOfInterest = regionOfInterest
    }
    
    private func startReadingRecordedVideoAsset(asset: AVAsset) {
        videoRenderView = VideoRenderView(frame: view.bounds)
        setupVideoOutputView(videoRenderView)
        
        let displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
        displayLink.preferredFramesPerSecond = 0
        displayLink.isPaused = true
        displayLink.add(to: RunLoop.current, forMode: .default)
        
        guard let track = asset.tracks(withMediaType: .video).first else {
            print("No video tracks found in AVAsset.")
            return
        }
        
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        let settings = [
            String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        
        let output = AVPlayerItemVideoOutput(pixelBufferAttributes: settings)
        playerItem.add(output)
        player.actionAtItemEnd = .pause
        player.play()
        
        self.displayLink = displayLink
        self.playerItemOutput = output
        self.videoRenderView.player = player
        
        let affineTransform = track.preferredTransform.inverted()
        let angleInDegrees = atan2(affineTransform.b, affineTransform.a) * CGFloat(180) / CGFloat.pi
        var orientation: UInt32 = 1
        switch angleInDegrees {
        case 0:
            orientation = 1 // Recording button is on the right
        case 180, -180:
            orientation = 3 // abs(180) degree rotation recording button is on the right
        case 90:
            orientation = 8 // ]90 degree CW rotation recording button is on the top
        case -90:
            orientation = 6 // 90 degree CCW rotation recording button is on the bottom
        default:
            orientation = 1
        }
        videoFileBufferOrientation = CGImagePropertyOrientation(rawValue: orientation)!
        videoFileFrameDuration = track.minFrameDuration
        displayLink.isPaused = false
    }
    
    private func setupVideoOutputView(_ videoOutputView: UIView) {
        videoOutputView.translatesAutoresizingMaskIntoConstraints = false
        videoOutputView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        view.addSubview(videoOutputView)
        NSLayoutConstraint.activate([
            videoOutputView.leftAnchor.constraint(equalTo: view.leftAnchor),
            videoOutputView.rightAnchor.constraint(equalTo: view.rightAnchor),
            videoOutputView.topAnchor.constraint(equalTo: view.topAnchor),
            videoOutputView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc
    private func handleDisplayLink(_ displayLink: CADisplayLink) {
        guard let output = playerItemOutput else {
            return
        }
        
        videoFileReadingQueue.async {
            let nextTimeStamp = displayLink.timestamp + displayLink.duration
            let itemTime = output.itemTime(forHostTime: nextTimeStamp)
            guard output.hasNewPixelBuffer(forItemTime: itemTime) else {
                return
            }
            guard let pixelBuffer = output.copyPixelBuffer(forItemTime: itemTime, itemTimeForDisplay: nil) else {
                return
            }
            // Create sample buffer from pixel buffer
            var sampleBuffer: CMSampleBuffer?
            var formatDescription: CMVideoFormatDescription?
            CMVideoFormatDescriptionCreateForImageBuffer(allocator: nil, imageBuffer: pixelBuffer, formatDescriptionOut: &formatDescription)
            let duration = self.videoFileFrameDuration
            var timingInfo = CMSampleTimingInfo(duration: duration, presentationTimeStamp: itemTime, decodeTimeStamp: itemTime)
            CMSampleBufferCreateForImageBuffer(allocator: nil,
                                               imageBuffer: pixelBuffer,
                                               dataReady: true,
                                               makeDataReadyCallback: nil,
                                               refcon: nil,
                                               formatDescription: formatDescription!,
                                               sampleTiming: &timingInfo,
                                               sampleBufferOut: &sampleBuffer)
            if let sampleBuffer = sampleBuffer {
                self.visionDetectTrajectoryRequest (sampleBuffer: sampleBuffer)
            }
        }
    }
    
    private func visionDetectTrajectoryRequest(sampleBuffer: CMSampleBuffer) {
        do {
            let requestHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer)
            try requestHandler.perform([request])
            request.regionOfInterest = regionOfInterest
        } catch{
            print("Error performing vision request: \(error)")
        }
    }
    
    func trajectoryRequestCompletionHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNTrajectoryObservation] else { return }
        
        for path in observations {
            if path.confidence > 0.99 {
                print(path.projectedPoints.count)
                DispatchQueue.main.async {
                    self.trajectoryView.duration = path.timeRange.duration.seconds
                    self.trajectoryView.points = path.detectedPoints
                }
            }
        }
    }

    private func calculateTrajectorySize(from points: [VNPoint]) -> CGSize {
        // Calculate the bounding box size based on detected points
        let xs = points.map { $0.location.x }
        let ys = points.map { $0.location.y }
        let width = (xs.max() ?? 0) - (xs.min() ?? 0)
        let height = (ys.max() ?? 0) - (ys.min() ?? 0)
        return CGSize(width: width, height: height)
    }

}

extension CGAffineTransform {
    static var verticalFlip = CGAffineTransform(scaleX: 1, y: -1).translatedBy (x: 0, y: -1)
}
