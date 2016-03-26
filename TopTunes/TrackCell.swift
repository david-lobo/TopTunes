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
    
    var imageCache = NSCache()
    weak var delegate: TrackCellDelegate?
    var downloadTask: NSURLSessionDownloadTask?
    var previewURL: NSURL!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var artworkImageButton: PreviewButton!
    @IBOutlet weak var rankLabel: UILabel!
    
    func configureForSearchResult(searchResult: Track, rank: Int, currentlyPlaying: Bool) {
        
        rankLabel.text = String(rank)
        nameLabel.text = searchResult.name
        
        if searchResult.artistName.isEmpty {
            artistNameLabel.text = NSLocalizedString("Unknown", comment: "Empty field value: Artist name")
        } else {
            artistNameLabel.text = searchResult.artistName
        }
        
        if searchResult.previewURL != "" {
            previewURL = NSURL(string: searchResult.previewURL)
        }
        
        loadImageWithURL(searchResult)
        
        artworkImageButton.changeState(currentlyPlaying ? PreviewButton.State.Playing : PreviewButton.State.Stopped, withAnimation: false)
    }
    
    func setPreviewButtonState(newState: PreviewButton.State, withAnimation: Bool = true) {
        artworkImageButton.changeState(newState, withAnimation: withAnimation)
    }
    
    //*****************************************************************
    // Load the image from cache or async from remote if needed
    //*****************************************************************
    
    func loadImageWithURL(searchResult: Track) {
        if let imageURL = NSURL(string: searchResult.artworkURL60) {
            if let image = imageCache.objectForKey(searchResult.artworkURL60) as? UIImage {
                
                // set the ImageView image from the cache
                artworkImageButton.playImageView.image = image
            } else {
                let downloadTask = NSURLSession.sharedSession().dataTaskWithURL(imageURL, completionHandler: { data, response, error in
                    
                    if error != nil {
                        print(error)
                        return
                    }
                    
                    let image = UIImage(data: data!)
                    
                    // set the image to cache
                    self.imageCache.setObject(image!, forKey: searchResult.artworkURL60)
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        
                        self.artworkImageButton.playImageView.image = image
                    }
                })
                
                downloadTask.resume()
            }
        }
    }
    
    @IBAction func previewButtonTapped() {
        if artworkImageButton.previewState == PreviewButton.State.Stopped {
            delegate?.trackCellDidTapStartButton(self)
        } else {
            delegate?.trackCellDidTapStopButton(self)
        }
    }
}