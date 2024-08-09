//
//  ViewController.swift
//  TrackingTrajectoriesDemo
//
//  Created by USER on 01.08.2024.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    private let selectVideoButton = UIButton()
    private let selectLiveFeedButton = UIButton()
    
    private var videoAsset: AVAsset?
    private let videoManager = VideoManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        self.view.addSubview(selectVideoButton)
        self.view.addSubview(selectLiveFeedButton)
        setupVideoButton()
        setupLiveFeedButton()
    }
    
    private func setupVideoButton() {
        selectVideoButton.translatesAutoresizingMaskIntoConstraints = false
        selectVideoButton.heightAnchor.constraint (equalToConstant: 50).isActive = true
        selectVideoButton.widthAnchor.constraint (equalToConstant: 250).isActive = true
        selectVideoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        selectVideoButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        selectVideoButton.addTarget(self,
                                    action: #selector(selectVideoButtonPressed),
                                    for: .touchUpInside)
        selectVideoButton.backgroundColor = .systemBlue
        selectVideoButton.setTitleColor(.white, for: .normal)
        selectVideoButton.setTitle("Analyze Recorded Video", for: .normal)
    }
    
    private func setupLiveFeedButton() {
        selectLiveFeedButton.translatesAutoresizingMaskIntoConstraints = false
        selectLiveFeedButton.heightAnchor.constraint(equalTo: selectVideoButton.heightAnchor).isActive =
        true
        selectLiveFeedButton.widthAnchor.constraint(equalTo: selectVideoButton.widthAnchor).isActive = true
        selectLiveFeedButton.topAnchor.constraint(equalTo: selectVideoButton.bottomAnchor, constant:
                                                    25).isActive = true
        selectLiveFeedButton.leadingAnchor.constraint(equalTo: selectVideoButton.leadingAnchor).isActive =
        true
        selectLiveFeedButton.addTarget(self,
                                       action: #selector(selectLiveFeedButtonPressed),
                                       for: .touchUpInside)
        selectLiveFeedButton.setTitle("Analyze Camera Feed", for: .normal)
        selectLiveFeedButton.backgroundColor = .systemBlue
        selectLiveFeedButton.setTitleColor(.white, for: .normal)
    }
    
    @objc private func selectVideoButtonPressed() {
        let docPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.movie], asCopy: true)
        docPicker.delegate = self
        present (docPicker, animated: true)
    }
    
    @objc private func selectLiveFeedButtonPressed() {
    }
}

// MARK: - UIDocumentPickerDelegate
extension ViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        self.videoManager.videoAsset = AVAsset(url: url)
        let vc = VideoViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
