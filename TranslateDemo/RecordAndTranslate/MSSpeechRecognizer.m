//
//  MSSpeechRecognizer.m
//  one mini
//
//  Created by 姜政 on 2018/11/7.
//  Copyright © 2018 te iol8. All rights reserved.
//

#import "MSSpeechRecognizer.h"
//#import "TRRecordVoiceStatus.h"
#import <MicrosoftCognitiveServicesSpeech/SPXSpeechApi.h>

@interface MSSpeechRecognizer ()<OMRecordManagerDelegate>
{
    
}
@property (nonatomic, strong)    SPXTranslationRecognizer * speechRecognizer;
@property(nonatomic) BOOL  isFinish;
@property(nonatomic, strong) NSMutableArray                         *results;
@property(nonatomic, strong) SPXPushAudioInputStream *inputStream;
@property (nonatomic,strong)OMRecordManager *record;
@end
@implementation MSSpeechRecognizer
-(instancetype)initWithDelegate:(id<MSSpeechRecognizerDelegate>)delegate{
    if (self = [super init]) {
        self.delegate = delegate;
       
    }
    return self;
}
-(void)setSourceLanguageId:(NSString *)sourceLanguageId destinationLanguageId:(NSString *)destinationLanguageId direction:(LangDirection)direction{
    self.sourceLanguageId = sourceLanguageId;
    self.destinationLanguageId = destinationLanguageId;
    
}
-(void)setSourceLanguageId:(NSString *)sourceLanguageId{
    _sourceLanguageId = sourceLanguageId;
    //    [TRRecordVoiceStatus sharedView].sourceLanguageId = sourceLanguageId;
}
-(void)setDestinationLanguageId:(NSString *)destinationLanguageId{
    _destinationLanguageId = destinationLanguageId;
    //    [TRRecordVoiceStatus sharedView].destinationLanguageId = destinationLanguageId;
}
-(NSMutableArray *)results{
    if (!_results) {
        _results = [[NSMutableArray alloc] init];
    }
    return _results;
}
-(SPXPushAudioInputStream *)inputStream{
    if (!_inputStream) {
        SPXAudioStreamFormat *format  =[[SPXAudioStreamFormat alloc] initUsingPCMWithSampleRate:44100 bitsPerSample:16 channels:1];
        
        _inputStream = [[SPXPushAudioInputStream alloc] initWithAudioFormat:format];
    }
    return _inputStream;

}
-(void)startRecognizer{
    [self.results removeAllObjects];
    self.isFinish = false;
    NSString *speechKey = @"fe48990fe872428d93fa304dc79868ff";
    NSString *serviceRegion = @"westus";
    self.recognizerID =  [NSString stringWithFormat:@"%@",@([NSDate timeIntervalSinceReferenceDate])];
    SPXSpeechTranslationConfiguration *speechConfig = [[SPXSpeechTranslationConfiguration alloc] initWithSubscription:speechKey region:serviceRegion];
    [speechConfig setSpeechRecognitionLanguage:self.sourceLanguageId];
    [speechConfig addTargetLanguage:self.destinationLanguageId];
    if (!speechConfig) {
        NSLog(@"Could not load speech config");
        //        [self updateRecognitionErrorText:(@"Speech Config Error")];
        return;
    }
    SPXAudioConfiguration *audioConfiguration = [[SPXAudioConfiguration alloc] initWithStreamInput:self.inputStream];
  
     _speechRecognizer = [[SPXTranslationRecognizer alloc] initWithSpeechTranslationConfiguration:speechConfig audioConfiguration:audioConfiguration];
    if (!_speechRecognizer) {
        NSLog(@"Could not create speech recognizer");
        //        [self updateRecognitionResultText:(@"Speech Recognition Error")];
        return;
    }
    __weak typeof(self) weakMS = self;
    [_speechRecognizer  addRecognizedEventHandler:^(SPXTranslationRecognizer * recognizer, SPXTranslationRecognitionEventArgs * eventArgs) {
        NSLog(@"reason:%@",@(eventArgs.result.reason));
        [weakMS.results addObject:eventArgs.result];
        [weakMS updateRecognitionResult];
    }];
    [_speechRecognizer addRecognizingEventHandler:^(SPXTranslationRecognizer * recognizer, SPXTranslationRecognitionEventArgs * eventArgs) {
        [weakMS.results addObject:eventArgs.result];
        [weakMS updateRecognitionResult];
        [weakMS.results removeLastObject];
    
    }];
    
    [_speechRecognizer addCanceledEventHandler:^(SPXTranslationRecognizer * recognizer, SPXTranslationRecognitionCanceledEventArgs * eventArgs) {
        [weakMS updateRecognitionResult];
        NSLog(@"cancel recognizer:%@",eventArgs.errorDetails);
    }];
    [_speechRecognizer addSessionStartedEventHandler:^(SPXRecognizer * recognizer, SPXSessionEventArgs * eventArgs) {
        NSLog(@"addSessionStartedEventHandler");
    }];
    
    [_speechRecognizer addSessionStoppedEventHandler:^(SPXRecognizer * recognizer, SPXSessionEventArgs * eventArgs) {
        NSLog(@"addSessionStoppedEventHandler");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakMS teardown];
        });
    }];
    [_speechRecognizer startContinuousRecognition];
    [self.record startRecorder];

}
-(void)updateRecognitionResult{
    NSMutableString *result = [[NSMutableString alloc] init];
    NSMutableString *translation =  [[NSMutableString alloc] init];
    for (int i=0; i<self.results.count; i++) {
        SPXTranslationRecognitionResult *speechResult = self.results[i];
          if (SPXResultReason_TranslatingSpeech == speechResult.reason||SPXResultReason_TranslatedSpeech== speechResult.reason) {
              [result appendString:speechResult.text];
              [translation appendString:speechResult.translations.allValues.firstObject];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(machineTranslator:recognition:direction:recognizerID:finish:)]) {
            [self.delegate machineTranslator:translation recognition:result direction:self.direction recognizerID:self.recognizerID finish:self.isFinish];
        }
    });
}
-(void)completeRecognizer{
    [self.inputStream close];
    [self.record stopRecorder];
    [_speechRecognizer stopContinuousRecognition];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isFinish = YES;
        //强行调用一次
        [self updateRecognitionResult];
    });
}

- (void)teardown
{
    [self.results removeAllObjects];
    self.speechRecognizer = nil;
}


-(void)cancelRecognizer{

}


-(void)configRecord:(OMRecordManager *)record{
    _record = record;
    _record.delegate = self;
}
-(void)didRecordData:(NSData *)pcmData{
    [_inputStream write:pcmData];
}

@end

