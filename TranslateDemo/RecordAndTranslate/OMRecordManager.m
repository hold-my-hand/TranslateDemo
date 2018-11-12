//
//  OMRecordManager.m
//  one mini
//
//  Created by 姜政 on 2018/11/12.
//  Copyright © 2018 te iol8. All rights reserved.
//

#import "OMRecordManager.h"
#define INPUT_BUS 1
#define OUTPUT_BUS 0
#define DEF_mSampleRate 16000
#define DEF_numberOfChannels 1

AudioUnit audioUnit;
AudioBufferList *buffList;

static OMRecordManager    *_instance = nil;

@implementation OMRecordManager
+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

#pragma mark - init

- (instancetype)init {
    self = [super init];
    
    if (self) {
        AudioUnitInitialize(audioUnit);
        [self initRemoteIO];
    }
    
    return self;
}

- (void)initRemoteIO {
    [self initAudioSession];
    
    [self initBuffer];
    
    [self initAudioComponent];
    
    [self initFormat];
    
    [self initAudioProperty];
    
    [self initRecordeCallback];
    
    [self initPlayCallback];
}

- (void)initAudioSession {
    NSError *error;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:&error];
    [audioSession setPreferredSampleRate:DEF_mSampleRate error:&error];
    [audioSession setPreferredInputNumberOfChannels:DEF_numberOfChannels error:&error];
    [audioSession setPreferredIOBufferDuration:0.023 error:&error];
    
}

- (void)initBuffer {
    UInt32 flag = 0;
    AudioUnitSetProperty(audioUnit,
                         kAudioUnitProperty_ShouldAllocateBuffer,
                         kAudioUnitScope_Output,
                         INPUT_BUS,
                         &flag,
                         sizeof(flag));
    
    buffList = (AudioBufferList*)malloc(sizeof(AudioBufferList));
    buffList->mNumberBuffers = 1;
    buffList->mBuffers[0].mNumberChannels = 1;
    
    buffList->mBuffers[0].mDataByteSize = 1024 * sizeof(short);
    buffList->mBuffers[0].mData = (short *)malloc(sizeof(short) * 1024);
}

- (void)initAudioComponent {
    AudioComponentDescription audioDesc;
    audioDesc.componentType = kAudioUnitType_Output;
    audioDesc.componentSubType = kAudioUnitSubType_RemoteIO;
    audioDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    audioDesc.componentFlags = 0;
    audioDesc.componentFlagsMask = 0;
    
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &audioDesc);
    AudioComponentInstanceNew(inputComponent, &audioUnit);
}

- (void)initFormat {
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate = DEF_mSampleRate;
    audioFormat.mFormatID = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioFormat.mFramesPerPacket = 1;
    audioFormat.mChannelsPerFrame = 1;
    audioFormat.mBitsPerChannel = 16;
    audioFormat.mBytesPerPacket = 2;
    audioFormat.mBytesPerFrame = 2;
    
    AudioUnitSetProperty(audioUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Output,
                         OUTPUT_BUS,
                         &audioFormat,
                         sizeof(audioFormat));
    AudioUnitSetProperty(audioUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Input,
                         INPUT_BUS,
                         &audioFormat,
                         sizeof(audioFormat));
}

- (void)initRecordeCallback {
    AURenderCallbackStruct recordCallback;
    recordCallback.inputProc = RecordCallback;
    recordCallback.inputProcRefCon = (__bridge void *)self;
    AudioUnitSetProperty(audioUnit,
                         kAudioOutputUnitProperty_SetInputCallback,
                         kAudioUnitScope_Global,
                         INPUT_BUS,
                         &recordCallback,
                         sizeof(recordCallback));
}

- (void)initPlayCallback {
    AURenderCallbackStruct playCallback;
    playCallback.inputProc = PlayCallback;
    playCallback.inputProcRefCon = (__bridge void *)self;
    AudioUnitSetProperty(audioUnit,
                         kAudioUnitProperty_SetRenderCallback,
                         kAudioUnitScope_Global,
                         OUTPUT_BUS,
                         &playCallback,
                         sizeof(playCallback));
}

- (void)initAudioProperty {
    UInt32 flag = 1;
    
    AudioUnitSetProperty(audioUnit,
                         kAudioOutputUnitProperty_EnableIO,
                         kAudioUnitScope_Input,
                         INPUT_BUS,
                         &flag,
                         sizeof(flag));
    AudioUnitSetProperty(audioUnit,
                         kAudioOutputUnitProperty_EnableIO,
                         kAudioUnitScope_Input,
                         OUTPUT_BUS,
                         &flag,
                         sizeof(flag));
    
}
-(void)didRecordData:(NSData *)pcmData{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didRecordData:)]) {
        [self.delegate didRecordData:pcmData];
    }
}
-(void)didRecordBuffer:(AudioBuffer)buffer bufferList:(AudioBufferList *)list{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didRecordBuffer:bufferList:)]) {
        [self.delegate didRecordBuffer:buffer bufferList:list];
    }
}
#pragma mark - callback function

static OSStatus RecordCallback(void *inRefCon,
                               AudioUnitRenderActionFlags *ioActionFlags,
                               const AudioTimeStamp *inTimeStamp,
                               UInt32 inBusNumber,
                               UInt32 inNumberFrames,
                               AudioBufferList *ioData)
{
    OMRecordManager *record = (__bridge OMRecordManager *)inRefCon;
    @autoreleasepool {
        OSStatus err = noErr;
        err =   AudioUnitRender(audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, buffList);

        AudioBuffer buffer = buffList->mBuffers[0]; // Left
        NSData *pcmBlock = [NSData dataWithBytes:buffer.mData length:buffer.mDataByteSize];
        [record didRecordData:pcmBlock];
    //        if (err) {
    //            NSLog(@"AudioUnitRender error code = %d", err);
    //        }else{
    //
    //        }
//        [record didRecordBuffer:buffer bufferList:buffList];
        //    short *data = (short *)buffList->mBuffers[0].mData;
    
//        NSLog(@"%d %d %d ", buffList->mBuffers[0].mDataByteSize, inBusNumber, inNumberFrames);
        
        
    }

    return noErr;
}

static OSStatus PlayCallback(void *inRefCon,
                             AudioUnitRenderActionFlags *ioActionFlags,
                             const AudioTimeStamp *inTimeStamp,
                             UInt32 inBusNumber,
                             UInt32 inNumberFrames,
                             AudioBufferList *ioData) {
    //    memcpy(ioData->mBuffers[0].mData, buffList->mBuffers[0].mData, buffList->mBuffers[0].mDataByteSize);
    AudioUnitRender(audioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
    
    return noErr;
}

#pragma mark - public methods

- (void)startRecorder {
    AudioOutputUnitStart(audioUnit);
}

- (void)stopRecorder {
    AudioOutputUnitStop(audioUnit);
}


@end

