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
    
    var recordings = [URL]()
    var player:AVAudioPlayer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // set the recordings array
        listRecordings()
        
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(RecordingsCollectionViewController.longPress(_:)))
        recognizer.minimumPressDuration = 0.5 //seconds
        recognizer.delegate = self
        recognizer.delaysTouchesBegan = true
        self.collectionView?.addGestureRecognizer(recognizer)
        
        let doubleTap = UITapGestureRecognizer(target:self, action:#selector(RecordingsCollectionViewController.doubleTap(_:)))
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
    
    func doubleTap(_ rec:UITapGestureRecognizer) {
        if rec.state != .ended {
            return
        }
        
        let p = rec.location(in: self.collectionView)
        if let indexPath = self.collectionView?.indexPathForItem(at: p) {
            askToRename((indexPath as NSIndexPath).row)
        }
        
    }
    
    func longPress(_ rec:UILongPressGestureRecognizer) {
        if rec.state != .ended {
            return
        }
        let p = rec.location(in: self.collectionView)
        if let indexPath = self.collectionView?.indexPathForItem(at: p) {
            askToDelete((indexPath as NSIndexPath).row)
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
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.recordings.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! RecordingCollectionViewCell
        
        cell.label.text = recordings[(indexPath as NSIndexPath).row].lastPathComponent
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        print("selected \(recordings[(indexPath as NSIndexPath).row].lastPathComponent)")
        
        //var cell = collectionView.cellForItemAtIndexPath(indexPath)
        play(recordings[(indexPath as NSIndexPath).row])

    }
    
    func play(_ url:URL) {
        print("playing \(url)")

        do {
            self.player = try AVAudioPlayer(contentsOf: url)
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
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
            self.recordings = urls.filter( { (name: URL) -> Bool in
                return name.lastPathComponent.hasSuffix("m4a")
            })
           
        } catch let error as NSError {
            print(error.localizedDescription)
        } catch {
            print("something went wrong listing recordings")
        }
        
    }
    
    func askToDelete(_ row:Int) {
        let alert = UIAlertController(title: "Delete",
            message: "Delete Recording \(recordings[row].lastPathComponent)?",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {action in
            print("yes was tapped \(self.recordings[row])")
            self.deleteRecording(self.recordings[row])
        }))
        alert.addAction(UIAlertAction(title: "No", style: .default, handler: {action in
            print("no was tapped")
        }))
        self.present(alert, animated:true, completion:nil)
    }
    
    func askToRename(_ row:Int) {
        let recording = self.recordings[row]
        
        let alert = UIAlertController(title: "Rename",
            message: "Rename Recording \(recording.lastPathComponent)?",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {[unowned alert] action in
            print("yes was tapped \(self.recordings[row])")
            if let textFields = alert.textFields{
                let tfa = textFields as [UITextField]
                let text = tfa[0].text
                let url = URL(fileURLWithPath: text!)
                self.renameRecording(recording, to: url)
            }
        }))
        alert.addAction(UIAlertAction(title: "No", style: .default, handler: {action in
            print("no was tapped")
        }))
        alert.addTextField(configurationHandler: {textfield in
            textfield.placeholder = "Enter a filename"
            textfield.text = "\(recording.lastPathComponent)"
        })
        self.present(alert, animated:true, completion:nil)
    }
    
    func renameRecording(_ from:URL, to:URL) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let toURL = documentsDirectory.appendingPathComponent(to.lastPathComponent)
        
        print("renaming file \(from.absoluteString) to \(to) url \(toURL)")
        let fileManager = FileManager.default
        fileManager.delegate = self
        do {
            try FileManager.default.moveItem(at: from, to: toURL)
        } catch let error as NSError {
            print(error.localizedDescription)
        } catch {
            print("error renaming recording")
        }
        DispatchQueue.main.async(execute: {
            self.listRecordings()
            self.collectionView?.reloadData()
        })
        
    }

    
    func deleteRecording(_ url:URL) {
        
        print("removing file at \(url.absoluteString)")
        let fileManager = FileManager.default
        
        do {
            try fileManager.removeItem(at: url)
        } catch let error as NSError {
            print(error.localizedDescription)
        } catch {
            print("error deleting recording")
        }
        
        DispatchQueue.main.async(execute: {
            self.listRecordings()
            self.collectionView?.reloadData()
        })
    }
    
    
}

extension RecordingsCollectionViewController: FileManagerDelegate {

    func fileManager(_ fileManager: FileManager, shouldMoveItemAt srcURL: URL, to dstURL: URL) -> Bool {

        print("should move \(srcURL) to \(dstURL)")
        return true
    }
    
}

extension RecordingsCollectionViewController : UIGestureRecognizerDelegate {
    
}

