## Synopsis

TopTunes is an iOS app written in Swift that displays the top 10 songs from iTunes UK and plays a 30 second preview.

## Approach

- To get the iTunes data I use the [iTunes RSS Generator](https://itunes.apple.com/rss/generator/) with appropriate GET parameters.
- Loading the remote data is done in a class called SearchAPI.  This uses NSURLSession to retrieve the data asynchronously in JSON format.  
- SearchAPI also parses the JSON and then stores it in the model as Track objects.
- TrackListTableViewController is the main view controller, embedded within a navigation controller.  This displays the Track objects inside a custom UITableViewCell called TrackCell.
- To play the preview, I use AVPlayer and AVPlayerItem.  I originally considered using an open source library such as [StreamingKit](https://github.com/tumtumtum/StreamingKit), but I believed for this task I could achieve a good result with AVFoundation classes.
- Responding to player events is done by adding observers to the AVPlayerItem and creating handlers for relevant events.
- I have tried to handle the problem of variable network by displaying approriate alerts when connections cannot be made.  

## Improvements

- Activity indicators for the user when streaming is in progress.  e.g. when they press play and the stream is buffereing it could use an animation to indicate to user what is happening.  Also if the stream fails it could change button colour to red to indicate that.
- Better network detection - more accurate way of finding out if device has connectivity
