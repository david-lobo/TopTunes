//
//  TrackListTableViewController.swift
//  TopMusic
//
//  Created by david lobo on 17/03/2016.
//  Copyright © 2016 David Lobo. All rights reserved.
//

import UIKit
import AVFoundation

class TrackListTableViewController: UITableViewController {
    
    struct TableViewCellIds {
        static let trackCell = "TrackCell"
        static let noResultCell = "NoResultCell"
        static let loadingCell = "LoadingCell"
        static let errorCell = "ErrorCell"
    }

    var asset: AVURLAsset?
    var player: AVPlayer?
    var playerItem: AVPlayerItem?
    var currentPlayerIndexPath: NSIndexPath!
    var isCurrentlyPlaying = false

    private(set) var searchAPI = SearchAPI()
    
    //*****************************************************************
    // MARK: - View Lifecycle
    //*****************************************************************
    
    override func viewDidLoad() {
        
        // Register nib files for use later
        registerNibs()

        tableView.rowHeight = 80
        refreshControl?.tintColor = UIColor(red: 234 / 255, green: 128 / 255, blue: 252 / 255, alpha: 1/0)
        
        // Get the iTunes data feed
        performRemoteDataUpdate(true)
        
        // Pull to refresh action - disable cache so that its always fresh
        self.refreshControl?.addTarget(self, action: "refreshData", forControlEvents: UIControlEvents.ValueChanged)
    }
    
    override func viewWillAppear(animated: Bool) {
        addObservers()
    }
    
    override func viewWillDisappear(animated: Bool) {
        removeObservers()
    }

    //*****************************************************************
    // MARK: - Setup helpers
    //*****************************************************************
    
    func registerNibs() {

        // Register the nib for the 'Track' table cell
        var cellNib = UINib(nibName: TableViewCellIds.trackCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIds.trackCell)
        
        // Register the nib for 'No Result' table cell
        cellNib = UINib(nibName: TableViewCellIds.noResultCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIds.noResultCell)
        
        // Register the nib for 'Error' table cell
        cellNib = UINib(nibName: TableViewCellIds.errorCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIds.errorCell)
        
        // Register the nib for 'Loading' table cell
        cellNib = UINib(nibName: TableViewCellIds.loadingCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIds.loadingCell)
    }
    
    func addObservers() {
        
        // Adding observers to monitor state of playback
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "finishedPlaying:", name: AVPlayerItemDidPlayToEndTimeNotification, object: playerItem)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "failedPlaying:", name: AVPlayerItemFailedToPlayToEndTimeNotification, object: playerItem)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playbackStalled:", name: AVPlayerItemPlaybackStalledNotification, object: playerItem)
    }
    
    func removeObservers() {
        
        // Remove all observers
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //*****************************************************************
    // MARK: - Loading data
    //*****************************************************************
    
    func perfformRemoteDataUpdateWithoutCache() {
        performRemoteDataUpdate(false)
    }
    
    func performRemoteDataUpdate(cacheEnabled: Bool = true) {
        updateFromRemote(cacheEnabled, completion: { params in
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            if !params.success {

                self.showError("Error", titleComment: "Error Alert Title", message: "There was an error connecting to iTunes.  Please check your internet connection and try again", messageComment: "Error Alert Message")
            }
            
            if ((self.refreshControl?.refreshing) == true) {
                self.refreshControl!.endRefreshing()
            }
            
            self.tableView.reloadData()
        })
    }
    
    //*****************************************************************
    // MARK: - Actions
    //*****************************************************************
    
    func playWithURL(url:NSURL) {
        
        if self.player != nil {
            self.player?.pause()
        }
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true

        // Load the audio file async with AVURLAsset to avoid blocking the UI
        asset = AVURLAsset(URL: url)
        let keys = ["playable"]
        asset?.loadValuesAsynchronouslyForKeys(keys, completionHandler: {
            
            dispatch_async(dispatch_get_main_queue(), {
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                var error: NSError? = nil
                let status: AVKeyValueStatus = self.asset!.statusOfValueForKey("playable", error: &error)
                
                // If the asset has loaded, can try to play it
                if status == AVKeyValueStatus.Loaded {
                    if let asset = self.asset {
                        if self.playerItem != nil {
                            self.playerItem?.removeObserver(self, forKeyPath: "status")
                        }
                        
                        self.playerItem = AVPlayerItem(asset: asset)
                        
                        self.playerItem?.addObserver(self, forKeyPath: "status", options:NSKeyValueObservingOptions(), context: nil)
                        
                        if self.player != nil {
                            self.player?.replaceCurrentItemWithPlayerItem(self.playerItem)
                            self.player?.rate = 1.0
                        } else {
                            self.player = AVPlayer(playerItem: self.playerItem!)
                            
                        }
                        self.player?.play()
                    }
                    
                } else {
                    // If asset failed to load, display error alert
                    self.showError("Error", titleComment: "Error Alert Title", message: error!.localizedDescription, messageComment: "Error Alert Message")
                    //print("error loading asset\(error!)")
                }
            })
        })
    }
    
    func stopPlaying(cell: TrackCell, withAnimation: Bool = true) {
        
        // Attempt to stop playback if currently playing
        if isCurrentlyPlaying {
            cell.setPreviewButtonState(PreviewButton.State.Stopped, withAnimation: true)
            currentPlayerIndexPath = nil
            isCurrentlyPlaying = false
            player?.pause()
            player?.rate = 0.0
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
    
    func refreshData() {
        
        if isCurrentlyPlaying {
            if let currentPlayerIndexPath = currentPlayerIndexPath {
                let currentPlayerCell = tableView.cellForRowAtIndexPath(currentPlayerIndexPath) as! TrackCell
        
                stopPlaying(currentPlayerCell, withAnimation: false)
            }
        }
        perfformRemoteDataUpdateWithoutCache()
    }
    
    func showError(title: String, titleComment: String, message: String, messageComment: String) {
        let alert = UIAlertController(
            title: NSLocalizedString(title, comment: titleComment), message: NSLocalizedString(message, comment: messageComment),
            preferredStyle: .Alert)
        
        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
        
        alert.addAction(action)
        
        presentViewController(alert, animated: true, completion: nil)
    }
}

//*****************************************************************
// MARK: - TableViewDatasource
//*****************************************************************

extension TrackListTableViewController {
    // data source
    
    func updateFromRemote(cacheEnabled: Bool, completion: SearchAPI.SearchComplete) {
        searchAPI.performTopTenMusicSearch(cacheEnabled,completion:  completion)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch searchAPI.status {
        case .NotSearched, .Error, .Searching, .NoResultsFound:
            return 1
        case .ResultsFound:
            return searchAPI.results.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch searchAPI.status {
        case .NotSearched, .Error:
            
            // Displays Not Searched cell view
            return tableView.dequeueReusableCellWithIdentifier(TableViewCellIds.errorCell, forIndexPath: indexPath)
        case .Searching:
            
            // Displays the Loading cell and animated spinner
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIds.loadingCell, forIndexPath: indexPath)
            let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
            spinner.startAnimating()
            return cell
        case .NoResultsFound:
            
            // Displays No Results Found cell
            return tableView.dequeueReusableCellWithIdentifier(TableViewCellIds.noResultCell, forIndexPath: indexPath)
        case .ResultsFound:
            
            // Displays and configures the Track cell
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIds.trackCell, forIndexPath: indexPath) as! TrackCell
            
            // Assign delegate so can catch when button is tapped
            cell.delegate = self
            let searchResult = searchAPI.results[indexPath.row]
            
            var currentlyPlaying = false
            if currentPlayerIndexPath != nil && currentPlayerIndexPath.row == indexPath.row {
               currentlyPlaying = true
            }
            cell.configureForSearchResult(searchResult, rank: indexPath.row + 1, currentlyPlaying: currentlyPlaying)
            return cell
        }
    }
}

//*****************************************************************
// MARK: - TableViewDelegate
//*****************************************************************

extension TrackListTableViewController {
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if searchAPI.results.count == 0 {
            return nil
        } else {
            return indexPath
        }
    }
    
}

//*****************************************************************
// MARK: - AVPlayerItem Notifications
//*****************************************************************

extension TrackListTableViewController {
    
    func finishedPlaying(notification: NSNotification) {
        //print("finished playing notification")
        let stoppedPlayerItem: AVPlayerItem = notification.object as! AVPlayerItem
        stoppedPlayerItem.seekToTime(kCMTimeZero)
        
        let currentPlayerCell = tableView.cellForRowAtIndexPath(currentPlayerIndexPath) as! TrackCell
        currentPlayerCell.setPreviewButtonState(PreviewButton.State.Stopped, withAnimation: true)
        
        currentPlayerIndexPath = nil
        isCurrentlyPlaying = false

        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    func failedPlaying(notification: NSNotification) {
        //print("failed playing notification")
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    func playbackStalled(notification: NSNotification) {
        //print("playback stalled notification")
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        // Show/hide the indicator depending on whether the media is going to play
        if self.player?.currentItem?.status == AVPlayerItemStatus.ReadyToPlay {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        } else if self.player?.currentItem?.status == AVPlayerItemStatus.Failed {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
}

//*****************************************************************
// MARK: - TrackCellDelegate
//*****************************************************************

extension TrackListTableViewController: TrackCellDelegate {
    
    func trackCellDidTapStopButton(cell: TrackCell) {
        stopPlaying(cell)
    }
    
    func trackCellDidTapStartButton(cell: TrackCell) {
        let indexPath = tableView.indexPathForCell(cell)
        
        // Start tapped while another cell is already playing
        if isCurrentlyPlaying {
            
            if let currentPlayerIndexPath = currentPlayerIndexPath {
                
                if let currentPlayerCell = tableView.cellForRowAtIndexPath(currentPlayerIndexPath) {
                
                let currentTrackCell = currentPlayerCell as! TrackCell
                // Stop the current player
                currentTrackCell.setPreviewButtonState(PreviewButton.State.Stopped, withAnimation: true)
                }
            }
            currentPlayerIndexPath = indexPath
            isCurrentlyPlaying = true
            
            // Play the newly requested cell
            cell.setPreviewButtonState(PreviewButton.State.Playing, withAnimation: true)
            playWithURL(cell.previewURL)
            
        } else {
            
            // Set the preview button to 'Playing'
            cell.setPreviewButtonState(PreviewButton.State.Playing, withAnimation: true)
            currentPlayerIndexPath = indexPath
            isCurrentlyPlaying = true
            
            // Start playing the track
            playWithURL(cell.previewURL)
        }
    }
}
