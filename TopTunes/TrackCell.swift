//
//  TrackCell.swift
//  TopMusic
//
//  Created by david lobo on 17/03/2016.
//  Copyright © 2016 David Lobo. All rights reserved.
//

import UIKit
import AVFoundation

protocol TrackCellDelegate: class {
    func trackCellDidTapStopButton(cell: TrackCell)
    func trackCellDidTapStartButton(cell: TrackCell)
}

class TrackCell: UITableViewCell {
    
    weak var delegate: TrackCellDelegate?
    var downloadTask: NSURLSessionDownloadTask?
    var previewURL: NSURL!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var artworkImageButton: PreviewButton!
    @IBOutlet weak var rankLabel: UILabel!

    func configureForSearchResult(searchResult: Track, rank: Int) {
        
        rankLabel.text = String(rank)
        nameLabel.text = searchResult.name
    
        if searchResult.artistName.isEmpty {
            artistNameLabel.text = NSLocalizedString("Unknown", comment: "Empty field value: Artist name")
        } else {
            artistNameLabel.text = searchResult.artistName
        }
        
        if let url = NSURL(string: searchResult.artworkURL60) {
            downloadTask = artworkImageButton.loadImageWithURL(url)
        }
        
        if searchResult.previewURL != "" {
            previewURL = NSURL(string: searchResult.previewURL)
        }
    }
    
    func setPreviewButtonState(newState: PreviewButton.State, withAnimation: Bool = true) {
        artworkImageButton.changeState(newState, withAnimation: withAnimation)
    }
    
    @IBAction func previewButtonTapped() {
        if artworkImageButton.previewState == PreviewButton.State.Stopped {
            delegate?.trackCellDidTapStartButton(self)
        } else {
            delegate?.trackCellDidTapStopButton(self)
        }
    }
}