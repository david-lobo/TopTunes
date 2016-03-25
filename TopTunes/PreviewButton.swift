//
//  PreviewButton.swift
//  TopMusic
//
//  Created by david lobo on 21/03/2016.
//  Copyright © 2016 David Lobo. All rights reserved.
//

import UIKit

//*****************************************************************
// Preview Button
//*****************************************************************

// UIButton subclass with play/pause animation

class PreviewButton: UIButton {
    
    enum State {
        case Stopped
        case Playing
    }
    
    var previewState: PreviewButton.State = .Stopped
    var placeholderImageView: UIImageView!
    var playImageView: UIImageView!
    var stopImageView: UIImageView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        // play is either placeholder image or cover art from iTunes
        let playImage = UIImage(named: "music_gray");
        playImageView = UIImageView(image: playImage)
        playImageView.frame = CGRect(x: 0, y:0, width: 50, height: 50)
        
        // stop is a stop button image
        let stopImage = UIImage(named: "stop");
        stopImageView = UIImageView(image: stopImage)
        stopImageView.frame = CGRect(x: 0, y:0, width: 50, height: 50)
        
        self.addSubview(playImageView)
        self.addSubview(stopImageView)
        stopImageView.hidden = true
    }
    
    //*****************************************************************
    // Change to play or pause state with animation
    //*****************************************************************
    
    func changeState(toState: PreviewButton.State, withAnimation: Bool = true) {
        
        if toState == .Playing {
            
            // Change state to playing
            previewState = .Playing
            
            if withAnimation {
                stopImageView.hidden = false
                // Make the stop button visible
                UIView.transitionFromView(playImageView, toView: stopImageView, duration: 1, options: UIViewAnimationOptions.TransitionFlipFromRight, completion: nil)
            } else {
                stopImageView.hidden = false
                playImageView.hidden = true
            }
        } else if toState == .Stopped {
         
            // Change state to stopped
            previewState = .Stopped
            
            if withAnimation {
                playImageView.hidden = false
                // Make the play button visible
                UIView.transitionFromView(stopImageView,toView: playImageView, duration: 1, options: UIViewAnimationOptions.TransitionFlipFromRight, completion: nil)
            } else {
                stopImageView.hidden = true
                playImageView.hidden = false
            }
        }
    }
}

extension PreviewButton {
    
    //*****************************************************************
    // Load image async and replace the placeholder image when done
    //*****************************************************************
    
    func loadImageWithURL(url: NSURL) -> NSURLSessionDownloadTask {
        let session = NSURLSession.sharedSession()
        let downloadTask = session.downloadTaskWithURL(
            url, completionHandler: { [weak self] url, response, error in
    
                if error == nil, let url = url,
                    data = NSData(contentsOfURL: url), image = UIImage(data: data) {

                    dispatch_async(dispatch_get_main_queue()) {
                        if let strongSelf = self {
                            strongSelf.playImageView.image = image
                        }
                    }
                }
            })
        
        downloadTask.resume()
        return downloadTask
    }
}
