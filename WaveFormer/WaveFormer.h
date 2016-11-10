//
//  WaveFormer.h
//  WaveFormer
//
//  Created by Corey Walo on 11/6/16.
//  Copyright © 2016 Audio Armada. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>

@interface WaveFormer: NSObject

@property(nonatomic) NSURL *fileURL;
@property(nonatomic) ExtAudioFileRef extAudioFile;
@property(nonatomic) UInt64 numFrames;
@property(nonatomic) float *sampleBuffer;
@property(nonatomic) CGRect boundingRect;
@property(nonatomic) int resolution;

- (instancetype)init:(NSURL*)fileURL;
- (CGPathRef) waveformPath: (int)resolution :(BOOL) transformVertical;

@end
