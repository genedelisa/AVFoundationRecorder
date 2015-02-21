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
    
    var recordings:[String]!
    var player:AVAudioPlayer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Register cell classes
        //FIXME: bug in beta5
        //self.collectionView.registerClass(RecordingCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        // Do any additional setup after loading the view.
        
        // set the recordings array
        listRecordings()
        
        
        var recognizer = UILongPressGestureRecognizer(target: self, action: "longPress:")
        recognizer.minimumPressDuration = 0.5 //seconds
        recognizer.delegate = self
        recognizer.delaysTouchesBegan = true
        self.collectionView?.addGestureRecognizer(recognizer)
        
        var doubleTap = UITapGestureRecognizer(target:self, action:"doubleTap:")
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 1
        doubleTap.delaysTouchesBegan = true
        self.collectionView?.addGestureRecognizer(doubleTap)
    }
    
    /**
    Get the cell with which you interacted.
    */
    func getCell(rec:UIGestureRecognizer) -> UICollectionViewCell {
        var cell:UICollectionViewCell!
        
        var p = rec.locationInView(self.collectionView)
        var indexPath = self.collectionView?.indexPathForItemAtPoint(p)
        if indexPath == nil {
            NSLog("couldn't find index path");
        } else {
            cell = self.collectionView?.cellForItemAtIndexPath(indexPath!)
            NSLog("found cell at \(indexPath!.row)")
        }
        return cell
    }
    
    func doubleTap(rec:UITapGestureRecognizer) {
        if rec.state != .Ended {
            return
        }
        
        var p = rec.locationInView(self.collectionView)
        var indexPath = self.collectionView?.indexPathForItemAtPoint(p)
        if indexPath == nil {
            NSLog("couldn't find index path");
        } else {
            var cell = self.collectionView?.cellForItemAtIndexPath(indexPath!)
            NSLog("found cell at \(indexPath!.row)")
            askToRename(indexPath!.row)
        }
    }
    
    func longPress(rec:UILongPressGestureRecognizer) {
        if rec.state != .Ended {
            return
        }
        var p = rec.locationInView(self.collectionView)
        var indexPath = self.collectionView?.indexPathForItemAtPoint(p)
        if indexPath == nil {
            NSLog("couldn't find index path");
        } else {
            var cell = self.collectionView?.cellForItemAtIndexPath(indexPath!)
            NSLog("found cell at \(indexPath!.row)")
            askToDelete(indexPath!.row)
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

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as RecordingCollectionViewCell
        
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
        
        println("selected \(recordings[indexPath.row].lastPathComponent)")
        
        //var cell = collectionView.cellForItemAtIndexPath(indexPath)
        
        var docsDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        var url = NSURL(fileURLWithPath: docsDir + "/" + recordings[indexPath.row])
        play(url!)
    }
    
    func play(url:NSURL) {
        println("playing \(url)")
        var error: NSError?
        self.player = AVAudioPlayer(contentsOfURL: url, error: &error)
        if player == nil {
            if let e = error {
                println(e.localizedDescription)
            }
        }
        //            player.delegate = self
        player.prepareToPlay()
        player.volume = 1.0
        player.play()
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
        var docsDir =
        NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        var fileManager = NSFileManager.defaultManager()
        var error: NSError?
        var files = fileManager.contentsOfDirectoryAtPath(docsDir, error: &error) as [String]
        if let e = error {
            println(e.localizedDescription)
        }
        self.recordings = files.filter( { (name: String) -> Bool in
            //            name.hasPrefix("recording-"))
            return name.hasSuffix("m4a")
        })
    }
    
    func askToDelete(row:Int) {
        var alert = UIAlertController(title: "Delete",
            message: "Delete Recording \(recordings[row])?",
            preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: {action in
            println("yes was tapped \(self.recordings[row])")
            self.deleteRecording(self.recordings[row])
        }))
        alert.addAction(UIAlertAction(title: "No", style: .Default, handler: {action in
            println("no was tapped")
        }))
        self.presentViewController(alert, animated:true, completion:nil)
    }
    
    func askToRename(row:Int) {
        var recording = self.recordings[row]
        
        var alert = UIAlertController(title: "Rename",
            message: "Rename Recording \(recording)?",
            preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: {[unowned alert] action in
            println("yes was tapped \(self.recordings[row])")
            let tf = alert.textFields as [UITextField]
            self.renameRecording(recording, to: tf[0].text.lastPathComponent)
        }))
        alert.addAction(UIAlertAction(title: "No", style: .Default, handler: {action in
            println("no was tapped")
        }))
        alert.addTextFieldWithConfigurationHandler({textfield in
            textfield.placeholder = "Enter a filename"
            textfield.text = "\(recording)"
        })
        self.presentViewController(alert, animated:true, completion:nil)
    }
    
    func renameRecording(from:String, to:String) {
        var docsDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        var f = docsDir + "/" + from
        var t = docsDir + "/" + to
        println("renaming file \(f) to \(t)")
        var fileManager = NSFileManager.defaultManager()
        fileManager.delegate = self
        var error: NSError?
        fileManager.moveItemAtPath(f, toPath: t, error: &error)
        if let e = error {
            println(e.localizedDescription)
        }
        dispatch_async(dispatch_get_main_queue(), {
            self.listRecordings()
            self.collectionView?.reloadData()
        })
    }
    
    func deleteRecording(filename:String) {
        var docsDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        //        var url = NSURL(fileURLWithPath: docsDir + "/" + filename)
        println("removing file at \(docsDir)/\(filename)")
        var fileManager = NSFileManager.defaultManager()
        var error: NSError?
        fileManager.removeItemAtPath(docsDir + "/" + filename, error: &error)
        if let e = error {
            println(e.localizedDescription)
        }
        
        dispatch_async(dispatch_get_main_queue(), {
            self.listRecordings()
            self.collectionView?.reloadData()
        })
    }
    
    
}

extension RecordingsCollectionViewController: NSFileManagerDelegate {
    func fileManager(fileManager: NSFileManager!,
        shouldMoveItemAtURL srcURL: NSURL!,
        toURL dstURL: NSURL!) -> Bool {
            println("should move \(srcURL) to \(dstURL)")
            return true
    }
}

extension RecordingsCollectionViewController : UIGestureRecognizerDelegate {
    
}

