//
//  RecorderViewController.swift
//  SwiftAVFound
//
//  Created by Gene De Lisa on 8/11/14.
//  Copyright (c) 2014 Gene De Lisa. All rights reserved.
//

import UIKit
import AVFoundation

/**

Uses AVAudioRecorder to record a sound file and an AVAudioPlayer to play it back.

:author: Gene De Lisa

*/
class RecorderViewController: UIViewController {
    
    var recorder: AVAudioRecorder!
    
    var player:AVAudioPlayer!
    
    @IBOutlet var recordButton: UIButton!
    
    @IBOutlet var stopButton: UIButton!
    
    @IBOutlet var playButton: UIButton!
    
    @IBOutlet var statusLabel: UILabel!
    
    var meterTimer:NSTimer!
    
    var soundFileURL:NSURL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stopButton.enabled = false
        playButton.enabled = false
        setSessionPlayback()
        askForNotifications()
    }
    
    func updateAudioMeter(timer:NSTimer) {
        
        if recorder.recording {
            let min = Int(recorder.currentTime / 60)
            let sec = Int(recorder.currentTime % 60)
            let s = String(format: "%02d:%02d", min, sec)
            statusLabel.text = s
            recorder.updateMeters()
            // if you want to draw some graphics...
            var apc0 = recorder.averagePowerForChannel(0)
            var peak0 = recorder.peakPowerForChannel(0)
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        recorder = nil
        player = nil
    }
    
    @IBAction func removeAll(sender: AnyObject) {
        deleteAllRecordings()
    }
    
    @IBAction func record(sender: UIButton) {
        
        if player != nil && player.playing {
            player.stop()
        }
        
        if recorder == nil {
            print("recording. recorder nil")
            recordButton.setTitle("Pause", forState:.Normal)
            playButton.enabled = false
            stopButton.enabled = true
            recordWithPermission(true)
            return
        }
        
        if recorder != nil && recorder.recording {
            print("pausing")
            recorder.pause()
            recordButton.setTitle("Continue", forState:.Normal)
            
        } else {
            print("recording")
            recordButton.setTitle("Pause", forState:.Normal)
            playButton.enabled = false
            stopButton.enabled = true
            //            recorder.record()
            recordWithPermission(false)
        }
    }
    
    @IBAction func stop(sender: UIButton) {
        print("stop")

        recorder?.stop()
        player?.stop()
        
        meterTimer.invalidate()
        
        recordButton.setTitle("Record", forState:.Normal)
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        var error: NSError?
        if !session.setActive(false, error: &error) {
            print("could not make session inactive")
            if let e = error {
                print(e.localizedDescription)
                return
            }
        }
        playButton.enabled = true
        stopButton.enabled = false
        recordButton.enabled = true
        //recorder = nil
    }
    
    @IBAction func play(sender: UIButton) {
        play()
    }
    
    func play() {
        
        print("playing")
        var error: NSError?

        if let r = recorder {
            self.player = AVAudioPlayer(contentsOfURL: r.url, error: &error)
            if self.player == nil {
                if let e = error {
                    print(e.localizedDescription)
                }
            }
        } else {
            self.player = AVAudioPlayer(contentsOfURL: soundFileURL!, error: &error)
            if player == nil {
                if let e = error {
                    print(e.localizedDescription)
                }
            }
        }
        
        stopButton.enabled = true

        player.delegate = self
        player.prepareToPlay()
        player.volume = 1.0
        player.play()
    }
    

    
    func setupRecorder() {
        var format = NSDateFormatter()
        format.dateFormat="yyyy-MM-dd-HH-mm-ss"
        var currentFileName = "recording-\(format.stringFromDate(NSDate())).m4a"
        print(currentFileName)
        
        var dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        var docsDir: AnyObject = dirPaths[0]
        var soundFilePath = docsDir.stringByAppendingPathComponent(currentFileName)
        soundFileURL = NSURL(fileURLWithPath: soundFilePath)
        let filemanager = NSFileManager.defaultManager()
        if filemanager.fileExistsAtPath(soundFilePath) {
            // probably won't happen. want to do something about it?
            print("sound exists")
        }
        
        var recordSettings:[NSObject: AnyObject] = [
            AVFormatIDKey: kAudioFormatAppleLossless,
            AVEncoderAudioQualityKey : AVAudioQuality.Max.rawValue,
            AVEncoderBitRateKey : 320000,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey : 44100.0
        ]
        var error: NSError?
        recorder = AVAudioRecorder(URL: soundFileURL!, settings: recordSettings, error: &error)
        if let e = error {
            print(e.localizedDescription)
        } else {
            recorder.delegate = self
            recorder.meteringEnabled = true
            recorder.prepareToRecord() // creates/overwrites the file at soundFileURL
        }
    }
    
    func recordWithPermission(setup:Bool) {
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        // ios 8 and later
        if (session.respondsToSelector("requestRecordPermission:")) {
            AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
                if granted {
                    print("Permission to record granted")
                    self.setSessionPlayAndRecord()
                    if setup {
                        self.setupRecorder()
                    }
                    self.recorder.record()
                    self.meterTimer = NSTimer.scheduledTimerWithTimeInterval(0.1,
                        target:self,
                        selector:"updateAudioMeter:",
                        userInfo:nil,
                        repeats:true)
                } else {
                    print("Permission to record not granted")
                }
            })
        } else {
            print("requestRecordPermission unrecognized")
        }
    }
    
    func setSessionPlayback() {
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        var error: NSError?
        if !session.setCategory(AVAudioSessionCategoryPlayback, error:&error) {
            print("could not set session category")
            if let e = error {
                print(e.localizedDescription)
            }
        }
        if !session.setActive(true, error: &error) {
            print("could not make session active")
            if let e = error {
                print(e.localizedDescription)
            }
        }
    }
    
    func setSessionPlayAndRecord() {
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        var error: NSError?
        if !session.setCategory(AVAudioSessionCategoryPlayAndRecord, error:&error) {
            print("could not set session category")
            if let e = error {
                print(e.localizedDescription)
            }
        }
        if !session.setActive(true, error: &error) {
            print("could not make session active")
            if let e = error {
                print(e.localizedDescription)
            }
        }
    }
    
    func deleteAllRecordings() {
        if let docsDir =
            NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as? String {
                
                var fileManager = NSFileManager.defaultManager()
                var error: NSError?
                if let files = fileManager.contentsOfDirectoryAtPath(docsDir, error: &error) as? [String] {
                    if let e = error {
                        print(e.localizedDescription)
                    }
                    var recordings = files.filter( { (name: String) -> Bool in
                        return name.hasSuffix("m4a")
                    })
                    for var i = 0; i < recordings.count; i++ {
                        var path = docsDir + "/" + recordings[i]
                        
                        print("removing \(path)")
                        if !fileManager.removeItemAtPath(path, error: &error) {
                            NSLog("could not remove \(path)")
                        }
                        if let e = error {
                            print(e.localizedDescription)
                        }
                    }
                }
        }
        
    }
    
    func askForNotifications() {
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:"background:",
            name:UIApplicationWillResignActiveNotification,
            object:nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:"foreground:",
            name:UIApplicationWillEnterForegroundNotification,
            object:nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:"routeChange:",
            name:AVAudioSessionRouteChangeNotification,
            object:nil)
    }
    
    func background(notification:NSNotification) {
        print("background")
    }
    
    func foreground(notification:NSNotification) {
        print("foreground")
    }
    
    
    func routeChange(notification:NSNotification) {
        //      let userInfo:Dictionary<String,String!> = notification.userInfo as Dictionary<String,String!>
        //      let userInfo = notification.userInfo as Dictionary<String,[AnyObject]!>
        //  var reason = userInfo[AVAudioSessionRouteChangeReasonKey]
        
        // var userInfo: [NSObject : AnyObject]? { get }
        //let AVAudioSessionRouteChangeReasonKey: NSString!
        
        /*
        if let reason = notification.userInfo[AVAudioSessionRouteChangeReasonKey] as? NSNumber  {
        }
        
        if let info = notification.userInfo as? Dictionary<String,String> {
        
        
        if let rs = info["AVAudioSessionRouteChangeReasonKey"] {
        var reason =  rs.toInt()!
        
        if rs.integerValue == Int(AVAudioSessionRouteChangeReason.NewDeviceAvailable.toRaw()) {
        }
        
        switch reason  {
        case AVAudioSessionRouteChangeReason
        print("new device")
        }
        
        }
        }
        
        var description = userInfo[AVAudioSessionRouteChangePreviousRouteKey]
        */
        /*
        //        var reason = info.valueForKey(AVAudioSessionRouteChangeReasonKey) as UInt
        //var reason = info.valueForKey(AVAudioSessionRouteChangeReasonKey) as AVAudioSessionRouteChangeReason.Raw
        //var description = info.valueForKey(AVAudioSessionRouteChangePreviousRouteKey) as String
        print(description)
        
        switch reason {
        case AVAudioSessionRouteChangeReason.NewDeviceAvailable.toRaw():
        print("new device")
        case AVAudioSessionRouteChangeReason.OldDeviceUnavailable.toRaw():
        print("old device unavail")
        //case AVAudioSessionRouteChangeReasonCategoryChange
        //case AVAudioSessionRouteChangeReasonOverride
        //case AVAudioSessionRouteChangeReasonWakeFromSleep
        //case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory
        
        default:
        print("something or other")
        }
        */
    }
    
}

// MARK: AVAudioRecorderDelegate
extension RecorderViewController : AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder!,
        successfully flag: Bool) {
            print("finished recording \(flag)")
            stopButton.enabled = false
            playButton.enabled = true
            recordButton.setTitle("Record", forState:.Normal)
            
            // iOS8 and later
            var alert = UIAlertController(title: "Recorder",
                message: "Finished Recording",
                preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Keep", style: .Default, handler: {action in
                print("keep was tapped")
            }))
            alert.addAction(UIAlertAction(title: "Delete", style: .Default, handler: {action in
                print("delete was tapped")
                self.recorder.deleteRecording()
            }))
            self.presentViewController(alert, animated:true, completion:nil)
    }
    
    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder!,
        error: NSError!) {
            print("\(error.localizedDescription)")
    }
}

// MARK: AVAudioPlayerDelegate
extension RecorderViewController : AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        print("finished playing \(flag)")
        recordButton.enabled = true
        stopButton.enabled = false
    }
    
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer!, error: NSError!) {
        print("\(error.localizedDescription)")
    }
}

