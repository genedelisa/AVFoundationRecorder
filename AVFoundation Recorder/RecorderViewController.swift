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

- Author: Gene De Lisa

*/
class RecorderViewController: UIViewController {
    
    var recorder: AVAudioRecorder!
    
    var player:AVAudioPlayer!
    
    @IBOutlet var recordButton: UIButton!
    
    @IBOutlet var stopButton: UIButton!
    
    @IBOutlet var playButton: UIButton!
    
    @IBOutlet var statusLabel: UILabel!
    
    var meterTimer:NSTimer!
    
    var soundFileURL:NSURL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stopButton.enabled = false
        playButton.enabled = false
        setSessionPlayback()
        askForNotifications()
        checkHeadphones()
    }
    
    func updateAudioMeter(timer:NSTimer) {
        
        if recorder.recording {
            let min = Int(recorder.currentTime / 60)
            let sec = Int(recorder.currentTime % 60)
            let s = String(format: "%02d:%02d", min, sec)
            statusLabel.text = s
            recorder.updateMeters()
            // if you want to draw some graphics...
            //var apc0 = recorder.averagePowerForChannel(0)
            //var peak0 = recorder.peakPowerForChannel(0)
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
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false)
            playButton.enabled = true
            stopButton.enabled = false
            recordButton.enabled = true
        } catch let error as NSError {
            print("could not make session inactive")
            print(error.localizedDescription)
        }
       
        //recorder = nil
    }
    
    @IBAction func play(sender: UIButton) {
        setSessionPlayback()
        play()
    }
    
    func play() {
        
        var url:NSURL?
        if self.recorder != nil {
            url = self.recorder.url
        } else {
            url = self.soundFileURL!
        }
        print("playing \(url)")
        
        do {
            self.player = try AVAudioPlayer(contentsOfURL: url!)
            stopButton.enabled = true
            player.delegate = self
            player.prepareToPlay()
            player.volume = 1.0
            player.play()
        } catch let error as NSError {
            self.player = nil
            print(error.localizedDescription)
        }
        
    }

    
    func setupRecorder() {
        let format = NSDateFormatter()
        format.dateFormat="yyyy-MM-dd-HH-mm-ss"
        let currentFileName = "recording-\(format.stringFromDate(NSDate())).m4a"
        print(currentFileName)
       
        let documentsDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
         self.soundFileURL = documentsDirectory.URLByAppendingPathComponent(currentFileName)

        if NSFileManager.defaultManager().fileExistsAtPath(soundFileURL.absoluteString) {
            // probably won't happen. want to do something about it?
            print("soundfile \(soundFileURL.absoluteString) exists")
        }
        
        let recordSettings:[String : AnyObject] = [
            AVFormatIDKey: NSNumber(unsignedInt:kAudioFormatAppleLossless),
            AVEncoderAudioQualityKey : AVAudioQuality.Max.rawValue,
            AVEncoderBitRateKey : 320000,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey : 44100.0
        ]
        
        do {
            recorder = try AVAudioRecorder(URL: soundFileURL, settings: recordSettings)
            recorder.delegate = self
            recorder.meteringEnabled = true
            recorder.prepareToRecord() // creates/overwrites the file at soundFileURL
        } catch let error as NSError {
            recorder = nil
            print(error.localizedDescription)
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

        do {
            try session.setCategory(AVAudioSessionCategoryPlayback)
        } catch let error as NSError {
            print("could not set session category")
            print(error.localizedDescription)
        }
        do {
            try session.setActive(true)
        } catch let error as NSError {
            print("could not make session active")
            print(error.localizedDescription)
        }
    }
    
    func setSessionPlayAndRecord() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch let error as NSError {
            print("could not set session category")
            print(error.localizedDescription)
        }
        do {
            try session.setActive(true)
        } catch let error as NSError {
            print("could not make session active")
            print(error.localizedDescription)
        }
    }
    
    func deleteAllRecordings() {
        let docsDir =
        NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        
        let fileManager = NSFileManager.defaultManager()
        
        do {
            let files = try fileManager.contentsOfDirectoryAtPath(docsDir)
            var recordings = files.filter( { (name: String) -> Bool in
                return name.hasSuffix("m4a")
            })
            for var i = 0; i < recordings.count; i++ {
                let path = docsDir + "/" + recordings[i]
                
                print("removing \(path)")
                do {
                    try fileManager.removeItemAtPath(path)
                } catch let error as NSError {
                    NSLog("could not remove \(path)")
                    print(error.localizedDescription)
                }
            }
            
        } catch let error as NSError {
            print("could not get contents of directory at \(docsDir)")
            print(error.localizedDescription)
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
        print("routeChange \(notification.userInfo)")
        
        if let userInfo = notification.userInfo {
            //print("userInfo \(userInfo)")
            if let reason = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt {
                //print("reason \(reason)")
                switch AVAudioSessionRouteChangeReason(rawValue: reason)! {
                case AVAudioSessionRouteChangeReason.NewDeviceAvailable:
                    print("NewDeviceAvailable")
                    print("did you plug in headphones?")
                    checkHeadphones()
                case AVAudioSessionRouteChangeReason.OldDeviceUnavailable:
                    print("OldDeviceUnavailable")
                    print("did you unplug headphones?")
                    checkHeadphones()
                case AVAudioSessionRouteChangeReason.CategoryChange:
                    print("CategoryChange")
                case AVAudioSessionRouteChangeReason.Override:
                    print("Override")
                case AVAudioSessionRouteChangeReason.WakeFromSleep:
                    print("WakeFromSleep")
                case AVAudioSessionRouteChangeReason.Unknown:
                    print("Unknown")
                case AVAudioSessionRouteChangeReason.NoSuitableRouteForCategory:
                    print("NoSuitableRouteForCategory")
                case AVAudioSessionRouteChangeReason.RouteConfigurationChange:
                    print("RouteConfigurationChange")
                    
                }
            }
        }
        
        // this cast fails. that's why I do that goofy thing above.
//        if let reason = userInfo[AVAudioSessionRouteChangeReasonKey] as? AVAudioSessionRouteChangeReason {
//        }

        /*
        AVAudioSessionRouteChangeReasonUnknown = 0,
        AVAudioSessionRouteChangeReasonNewDeviceAvailable = 1,
        AVAudioSessionRouteChangeReasonOldDeviceUnavailable = 2,
        AVAudioSessionRouteChangeReasonCategoryChange = 3,
        AVAudioSessionRouteChangeReasonOverride = 4,
        AVAudioSessionRouteChangeReasonWakeFromSleep = 6,
        AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory = 7,
        AVAudioSessionRouteChangeReasonRouteConfigurationChange NS_ENUM_AVAILABLE_IOS(7_0) = 8
        
        routeChange Optional([AVAudioSessionRouteChangeReasonKey: 1, AVAudioSessionRouteChangePreviousRouteKey: <AVAudioSessionRouteDescription: 0x17557350,
        inputs = (
        "<AVAudioSessionPortDescription: 0x17557760, type = MicrophoneBuiltIn; name = iPhone Microphone; UID = Built-In Microphone; selectedDataSource = Bottom>"
        );
        outputs = (
        "<AVAudioSessionPortDescription: 0x17557f20, type = Speaker; name = Speaker; UID = Built-In Speaker; selectedDataSource = (null)>"
        )>])
        routeChange Optional([AVAudioSessionRouteChangeReasonKey: 2, AVAudioSessionRouteChangePreviousRouteKey: <AVAudioSessionRouteDescription: 0x175562f0,
        inputs = (
        "<AVAudioSessionPortDescription: 0x1750c560, type = MicrophoneBuiltIn; name = iPhone Microphone; UID = Built-In Microphone; selectedDataSource = Bottom>"
        );
        outputs = (
        "<AVAudioSessionPortDescription: 0x17557de0, type = Headphones; name = Headphones; UID = Wired Headphones; selectedDataSource = (null)>"
        )>])
*/
    }
    
    func checkHeadphones() {
        // check NewDeviceAvailable and OldDeviceUnavailable for them being plugged in/unplugged
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        if currentRoute.outputs.count > 0 {
            for description in currentRoute.outputs {
                if description.portType == AVAudioSessionPortHeadphones {
                    print("headphones are plugged in")
                    break
                } else {
                    print("headphones are unplugged")
                }
            }
        } else {
            print("checking headphones requires a connection to a device")
        }
    }
    
    @IBAction
    func trim() {
        if self.soundFileURL == nil {
            print("no sound file")
            return
        }
        
        print("trimming \(soundFileURL!.absoluteString)")
        print("trimming path \(soundFileURL!.lastPathComponent)")
        let asset = AVAsset(URL:self.soundFileURL!)
        exportAsset(asset, fileName: "trimmed.m4a")
    }
    
    func exportAsset(asset:AVAsset, fileName:String) {
        let documentsDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        let trimmedSoundFileURL = documentsDirectory.URLByAppendingPathComponent(fileName)
        print("saving to \(trimmedSoundFileURL.absoluteString)")


        
        if NSFileManager.defaultManager().fileExistsAtPath(trimmedSoundFileURL.absoluteString) {
            print("sound exists, removing \(trimmedSoundFileURL.absoluteString)")
            do {
                var error:NSError?
                if trimmedSoundFileURL.checkResourceIsReachableAndReturnError(&error) {
                    print("is reachable")
                }
                if let e = error {
                    print(e.localizedDescription)
                }
                
                try NSFileManager.defaultManager().removeItemAtPath(trimmedSoundFileURL.absoluteString)
            } catch let error as NSError {
                NSLog("could not remove \(trimmedSoundFileURL)")
                print(error.localizedDescription)
            }
           
        }
        
        if let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) {
            exporter.outputFileType = AVFileTypeAppleM4A
            exporter.outputURL = trimmedSoundFileURL
            
            let duration = CMTimeGetSeconds(asset.duration)
            if (duration < 5.0) {
                print("sound is not long enough")
                return
            }
            // e.g. the first 5 seconds
            let startTime = CMTimeMake(0, 1)
            let stopTime = CMTimeMake(5, 1)
            exporter.timeRange = CMTimeRangeFromTimeToTime(startTime, stopTime)
            
//            // set up the audio mix
//            let tracks = asset.tracksWithMediaType(AVMediaTypeAudio)
//            if tracks.count == 0 {
//                return
//            }
//            let track = tracks[0]
//            let exportAudioMix = AVMutableAudioMix()
//            let exportAudioMixInputParameters =
//            AVMutableAudioMixInputParameters(track: track)
//            exportAudioMixInputParameters.setVolume(1.0, atTime: CMTimeMake(0, 1))
//            exportAudioMix.inputParameters = [exportAudioMixInputParameters]
//            // exporter.audioMix = exportAudioMix
            
            // do it
            exporter.exportAsynchronouslyWithCompletionHandler({
                switch exporter.status {
                case  AVAssetExportSessionStatus.Failed:

                    if let e = exporter.error {
                        print("export failed \(e)")
                        switch e.code {
                        case AVError.FileAlreadyExists.rawValue:
                            print("File Exists")
                            break
                        default: break
                        }
                    } else {
                        print("export failed")
                    }
                case AVAssetExportSessionStatus.Cancelled:
                    print("export cancelled \(exporter.error)")
                default:
                    print("export complete")
                }
            })
        }
        
    }
    
    @IBAction
    func speed() {
        let asset = AVAsset(URL:self.soundFileURL!)
        exportSpeedAsset(asset, fileName: "trimmed.m4a")
    }
    
    func exportSpeedAsset(asset:AVAsset, fileName:String) {
        let documentsDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        let trimmedSoundFileURL = documentsDirectory.URLByAppendingPathComponent(fileName)
        
        let filemanager = NSFileManager.defaultManager()
        if filemanager.fileExistsAtPath(trimmedSoundFileURL.absoluteString) {
            print("sound exists")
        }
        
        if let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) {
            exporter.outputFileType = AVFileTypeAppleM4A
            exporter.outputURL = trimmedSoundFileURL
            
            
            //             AVAudioTimePitchAlgorithmVarispeed
            //             AVAudioTimePitchAlgorithmSpectral
            //             AVAudioTimePitchAlgorithmTimeDomain
            exporter.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmVarispeed
            
            
            
            
            let duration = CMTimeGetSeconds(asset.duration)
            if (duration < 5.0) {
                print("sound is not long enough")
                return
            }
            // e.g. the first 5 seconds
//            let startTime = CMTimeMake(0, 1)
//            let stopTime = CMTimeMake(5, 1)
//            let exportTimeRange = CMTimeRangeFromTimeToTime(startTime, stopTime)
//            exporter.timeRange = exportTimeRange
            
            // do it
            exporter.exportAsynchronouslyWithCompletionHandler({
                switch exporter.status {
                case  AVAssetExportSessionStatus.Failed:
                    print("export failed \(exporter.error)")
                case AVAssetExportSessionStatus.Cancelled:
                    print("export cancelled \(exporter.error)")
                default:
                    print("export complete")
                }
            })
        }
    }

    
}

// MARK: AVAudioRecorderDelegate
extension RecorderViewController : AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder,
        successfully flag: Bool) {
            print("finished recording \(flag)")
            stopButton.enabled = false
            playButton.enabled = true
            recordButton.setTitle("Record", forState:.Normal)
            
            // iOS8 and later
            let alert = UIAlertController(title: "Recorder",
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
    
    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder,
        error: NSError?) {
            
            if let e = error {
                print("\(e.localizedDescription)")
            }
    }
    
}

// MARK: AVAudioPlayerDelegate
extension RecorderViewController : AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        print("finished playing \(flag)")
        recordButton.enabled = true
        stopButton.enabled = false
    }
    
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?) {
        if let e = error {
            print("\(e.localizedDescription)")
        }
        
    }
}

