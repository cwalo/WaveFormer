//
//  WaveFormer.m
//  WaveFormer
//
//  Created by Corey Walo on 11/6/16.
//  Copyright © 2016 Audio Armada. All rights reserved.
//

#import "WaveFormer.h"

@implementation WaveFormer

@synthesize fileURL;
@synthesize extAudioFile;
@synthesize sampleBuffer;
@synthesize numFrames;
@synthesize resolution;

- (instancetype)init
{
    self = [super init];
    if (self) {}
    return self;
}

- (instancetype)init:(NSURL*)fileURL {
    self = [self init];
    
    self.fileURL = fileURL;
    sampleBuffer = [self processFile];

    return self;
}

- (float *) processFile {
    
    // cast our NSURL to a CFURL
    CFURLRef cfURL = CFBridgingRetain(fileURL);
    OSStatus error = ExtAudioFileOpenURL(cfURL, &extAudioFile);
    CFRelease(cfURL);
    
    // generate an ASBD
    AudioStreamBasicDescription asbd = {0};
    UInt32 propSize = sizeof(AudioStreamBasicDescription);
    
    CheckError(ExtAudioFileGetProperty(extAudioFile, kExtAudioFileProperty_FileDataFormat, &propSize, &asbd), "Get ASBD Failed");
    
    // get the number of samples
    SInt64 numSamples;
    propSize = sizeof(numSamples);

    CheckError(ExtAudioFileGetProperty(extAudioFile, kExtAudioFileProperty_FileLengthFrames, &propSize, &numSamples), "Get sample length failed");
    
    self.numFrames = numSamples;
    
    // Setting the file's client format allows us to tell it what format we expect
    AudioStreamBasicDescription clientFormat = {0};
    propSize = sizeof(clientFormat);
    
    clientFormat.mFormatID           = kAudioFormatLinearPCM;
    clientFormat.mSampleRate         = asbd.mSampleRate;
    clientFormat.mFormatFlags        = kAudioFormatFlagIsFloat;
    //kAudioFormatFlagsCanonical; //kAudioFormatFlagIsFloat | kAudioFormatFlagIsAlignedHigh | kAudioFormatFlagsCanonical; // | kAudioFormatFlagIsPacked | kAudioFormatFlagsNativeEndian; // |  kAudioFormatFlagIsNonInterleaved;
    clientFormat.mChannelsPerFrame   = asbd.mChannelsPerFrame;
    clientFormat.mBitsPerChannel     = sizeof(float) * 8;
    clientFormat.mFramesPerPacket    = 1;
    clientFormat.mBytesPerFrame      = asbd.mChannelsPerFrame * sizeof(float);
    clientFormat.mBytesPerPacket     = asbd.mChannelsPerFrame * sizeof(float);
    
    error = ExtAudioFileSetProperty(extAudioFile, kExtAudioFileProperty_ClientDataFormat, propSize, &clientFormat);
    
    // Create an audio buffer list to read samples into
    float *samples = (float*)malloc(numSamples*sizeof(float));
    
    AudioBufferList bufList;
    bufList.mNumberBuffers = 1;
    bufList.mBuffers[0].mNumberChannels = asbd.mChannelsPerFrame;
    bufList.mBuffers[0].mData = samples; // data is a pointer (float*) to our sample buffer
    bufList.mBuffers[0].mDataByteSize = numSamples * sizeof(float);
    
    CheckError(ExtAudioFileRead(extAudioFile, &numSamples, &bufList), "File read failed");
    
    return samples;
}

- (CGPoint *) bufferOverview {
    //creates a pointer array of CGPoints <pixelX, sampleValueY>
    
    CGPoint *reducedBuffer = (CGPoint*)malloc((numFrames / self.resolution )*sizeof(CGPoint));
    
    // normalizing the samples creates only positive values
    //[self normalizeSamples:sampleBuffer];
    
    for (long i = 1; i < numFrames; i += self.resolution) {
        float sample = sampleBuffer[i];
        CGPoint point = CGPointMake(i / self.resolution, sample);
        reducedBuffer[i / self.resolution] = point;
    }
    
    return reducedBuffer;
}

- (void) normalizeSamples:(float*)samples
{
    float min = MAXFLOAT;
    float max = -MAXFLOAT;
    for(int i = 0; i < numFrames; i++) {
        float val = fabsf(samples[i]);
        if(val < min) min = val;
        if(val > max) max = val;
    }
    
    //	long double delta = max - min;
    //	NSLog(@"Min: %f, Max: %f, Delta: %Lf", min,  max, delta);
    for(int i = 0; i < numFrames; i++) {
        float val = samples[i];
        val = val * 1.0/max;
        
        if(val > 1.0) val = 1.0;
        if(val < 0.0) val = 0.0;
        samples[i] = val;
    }
}

- (CGPathRef) waveformPath :(int)resolution :(BOOL)transformVertical {
    self.resolution = resolution;
    
    // Get the overview waveform data (taking into account the level of detail to
    // create the reduced data set)
    CGPathRef halfPath = [self halfPath];
    
    // Build the destination path
    CGMutablePathRef path = CGPathCreateMutable();
    
    // Transform to fit the waveform ([0,1] range) into the vertical space
    // ([halfHeight,height] range)
    
    double halfHeight = floor( NSHeight( self.boundingRect ) / 2.0 );
    CGAffineTransform xf = CGAffineTransformIdentity;
    xf = CGAffineTransformTranslate( xf, 0.0, halfHeight );
    xf = CGAffineTransformScale( xf, 1.0, halfHeight );
    
    // Add the transformed path to the destination path
    CGPathAddPath( path, &xf, halfPath );
    
    if (transformVertical) {
//     Transform to fit the waveform ([0,1] range) into the vertical space
//     ([0,halfHeight] range), flipping the Y axis
        xf = CGAffineTransformIdentity;
        xf = CGAffineTransformTranslate( xf, 0.0, halfHeight );
        xf = CGAffineTransformScale( xf, 1.0, -halfHeight );
    
        // Add the transformed path to the destination path
        CGPathAddPath( path, &xf, halfPath );
    }
    
    CGPathRelease( halfPath ); // clean up!
    
    // Now, path contains the full waveform path.
    return path;
}

- (CGPathRef) halfPath {
    //int resolution = 1;
    int pointCount = numFrames / self.resolution;
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddLines( path, NULL, [self bufferOverview], pointCount ); // magic!
    return path;
}

static void CheckError(OSStatus error, const char *operation)
{
    if (error == noErr) return;
    
    char str[20];
    // see if it appears to be a 4-char-code
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
    if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    } else
        // no, format it as an integer
        sprintf(str, "%d", (int)error);
    
    fprintf(stderr, "Error: %s (%s)\n", operation, str);
    
    exit(1);
}

@end
