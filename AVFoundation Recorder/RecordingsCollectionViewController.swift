//
//  RecordingsCollectionViewController.swift
//  AVFoundation Recorder
//
//  Created by Gene De Lisa on 8/13/14.
//  Copyright (c) 2014 Gene De Lisa. All rights reserved.
//

import UIKit
import AVFoundation

let reuseIdentifier = "recordingCell"

class RecordingsCollectionViewController: UICollectionViewController {
    
    var recordings = [NSURL]()
    var player:AVAudioPlayer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // set the recordings array
        listRecordings()
        
        let recognizer = UILongPressGestureRecognizer(target: self, action: "longPress:")
        recognizer.minimumPressDuration = 0.5 //seconds
        recognizer.delegate = self
        recognizer.delaysTouchesBegan = true
        self.collectionView?.addGestureRecognizer(recognizer)
        
        let doubleTap = UITapGestureRecognizer(target:self, action:"doubleTap:")
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 1
        doubleTap.delaysTouchesBegan = true
        self.collectionView?.addGestureRecognizer(doubleTap)
    }
    
    /**
    Get the cell with which you interacted.
    */
//    func getCell(rec:UIGestureRecognizer) -> UICollectionViewCell {
//        var cell:UICollectionViewCell!
//        
//        let p = rec.locationInView(self.collectionView)
//        let indexPath = self.collectionView?.indexPathForItemAtPoint(p)
//        if indexPath == nil {
//            NSLog("couldn't find index path");
//        } else {
//            cell = self.collectionView?.cellForItemAtIndexPath(indexPath!)
//            NSLog("found cell at \(indexPath!.row)")
//        }
//        return cell
//    }
    
    func doubleTap(rec:UITapGestureRecognizer) {
        if rec.state != .Ended {
            return
        }
        
        let p = rec.locationInView(self.collectionView)
        if let indexPath = self.collectionView?.indexPathForItemAtPoint(p) {
            askToRename(indexPath.row)
        }
        
    }
    
    func longPress(rec:UILongPressGestureRecognizer) {
        if rec.state != .Ended {
            return
        }
        let p = rec.locationInView(self.collectionView)
        if let indexPath = self.collectionView?.indexPathForItemAtPoint(p) {
            askToDelete(indexPath.row)
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.recordings.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! RecordingCollectionViewCell
        
        cell.label.text = recordings[indexPath.row].lastPathComponent
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        print("selected \(recordings[indexPath.row].lastPathComponent)")
        
        //var cell = collectionView.cellForItemAtIndexPath(indexPath)
        play(recordings[indexPath.row])

    }
    
    func play(url:NSURL) {
        print("playing \(url)")

        do {
            self.player = try AVAudioPlayer(contentsOfURL: url)
            player.prepareToPlay()
            player.volume = 1.0
            player.play()
        } catch let error as NSError {
            self.player = nil
            print(error.localizedDescription)
        } catch {
            print("AVAudioPlayer init failed")
        }
        
    }
    
    
    
    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    func collectionView(collectionView: UICollectionView!, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath!) -> Bool {
    return false
    }
    
    func collectionView(collectionView: UICollectionView!, canPerformAction action: String!, forItemAtIndexPath indexPath: NSIndexPath!, withSender sender: AnyObject!) -> Bool {
    return false
    }
    
    func collectionView(collectionView: UICollectionView!, performAction action: String!, forItemAtIndexPath indexPath: NSIndexPath!, withSender sender: AnyObject!) {
    
    }
    */
    
    
    
    func listRecordings() {
        
        let documentsDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        do {
            let urls = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(documentsDirectory, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsHiddenFiles)
            self.recordings = urls.filter( { (name: NSURL) -> Bool in
                return name.lastPathComponent!.hasSuffix("m4a")
            })
           
        } catch let error as NSError {
            print(error.localizedDescription)
        } catch {
            print("something went wrong listing recordings")
        }
        
    }
    
    func askToDelete(row:Int) {
        let alert = UIAlertController(title: "Delete",
            message: "Delete Recording \(recordings[row].lastPathComponent!)?",
            preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: {action in
            print("yes was tapped \(self.recordings[row])")
            self.deleteRecording(self.recordings[row])
        }))
        alert.addAction(UIAlertAction(title: "No", style: .Default, handler: {action in
            print("no was tapped")
        }))
        self.presentViewController(alert, animated:true, completion:nil)
    }
    
    func askToRename(row:Int) {
        let recording = self.recordings[row]
        
        let alert = UIAlertController(title: "Rename",
            message: "Rename Recording \(recording.lastPathComponent!)?",
            preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: {[unowned alert] action in
            print("yes was tapped \(self.recordings[row])")
            if let textFields = alert.textFields{
                let tfa = textFields as [UITextField]
                let text = tfa[0].text
                let url = NSURL(fileURLWithPath: text!)
                self.renameRecording(recording, to: url)
            }
        }))
        alert.addAction(UIAlertAction(title: "No", style: .Default, handler: {action in
            print("no was tapped")
        }))
        alert.addTextFieldWithConfigurationHandler({textfield in
            textfield.placeholder = "Enter a filename"
            textfield.text = "\(recording.lastPathComponent!)"
        })
        self.presentViewController(alert, animated:true, completion:nil)
    }
    
    func renameRecording(from:NSURL, to:NSURL) {
        let documentsDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        let toURL = documentsDirectory.URLByAppendingPathComponent(to.lastPathComponent!)
        
        print("renaming file \(from.absoluteString) to \(to) url \(toURL)")
        let fileManager = NSFileManager.defaultManager()
        fileManager.delegate = self
        do {
            try NSFileManager.defaultManager().moveItemAtURL(from, toURL: toURL)
        } catch let error as NSError {
            print(error.localizedDescription)
        } catch {
            print("error renaming recording")
        }
        dispatch_async(dispatch_get_main_queue(), {
            self.listRecordings()
            self.collectionView?.reloadData()
        })
        
    }

    
    func deleteRecording(url:NSURL) {
        
        print("removing file at \(url.absoluteString)")
        let fileManager = NSFileManager.defaultManager()
        
        do {
            try fileManager.removeItemAtURL(url)
        } catch let error as NSError {
            print(error.localizedDescription)
        } catch {
            print("error deleting recording")
        }
        
        dispatch_async(dispatch_get_main_queue(), {
            self.listRecordings()
            self.collectionView?.reloadData()
        })
    }
    
    
}

extension RecordingsCollectionViewController: NSFileManagerDelegate {

    func fileManager(fileManager: NSFileManager, shouldMoveItemAtURL srcURL: NSURL, toURL dstURL: NSURL) -> Bool {

        print("should move \(srcURL) to \(dstURL)")
        return true
    }
    
}

extension RecordingsCollectionViewController : UIGestureRecognizerDelegate {
    
}

