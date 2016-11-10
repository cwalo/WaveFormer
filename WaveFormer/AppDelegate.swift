//
//  AppDelegate.swift
//  WaveFormer
//
//  Created by Corey Walo on 11/6/16.
//  Copyright © 2016 Audio Armada. All rights reserved.
//

import Cocoa
import Foundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var waveformView: WaveFormView!

    var waveFormer: WaveFormer?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let path = Bundle.main.path(forResource: "drumLoop", ofType: "wav")
        let url = NSURL(fileURLWithPath: path!)
        waveFormer = WaveFormer(url as URL!)
        
        waveFormer?.boundingRect = waveformView.bounds
        
        let wavePath = waveFormer?.waveformPath(1, false);
        waveformView.path = wavePath?.takeRetainedValue()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @IBAction func didSlide(_ sender: NSSlider) {
        let wavePath = waveFormer?.waveformPath(sender.intValue, false);
        waveformView.path = wavePath?.takeRetainedValue()
    }
    
}

class WaveFormView : NSView {
    
    var firstDraw = true
    
    var path: CGPath? {
        didSet {
            needsDisplay = true
            displayIfNeeded()
        }
    }

    convenience init(path: CGPath) {
        self.init()
        
        self.path = path
    }
    
    override func draw(_ dirtyRect: NSRect) {
        
        if firstDraw {
            if let path = path {
                let context = NSGraphicsContext.current()?.cgContext
                context?.addPath(path)
                //context?.strokePath()
                context?.fillPath()
                
                //firstDraw = false
            }
            
        }
    }
}


