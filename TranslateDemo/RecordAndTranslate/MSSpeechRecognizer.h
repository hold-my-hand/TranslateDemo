//
//  MSSpeechRecognizer.h
//  one mini
//
//  Created by 姜政 on 2018/11/7.
//  Copyright © 2018 te iol8. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OMRecordManager.h"
typedef enum LangDirection{
    LeftDirection,
    RightDirection,
}LangDirection;

@protocol MSSpeechRecognizerDelegate <NSObject>
@optional
-(void)recognizerVoiceFailure;
-(void)machineTranslator:(NSString *)translation recognition:(NSString *)recognition direction:(LangDirection)direction recognizerID:(NSString *)recognizerID finish:(BOOL)finish;
@end

NS_ASSUME_NONNULL_BEGIN

@interface MSSpeechRecognizer : NSObject

@property(nonatomic,assign)LangDirection direction;
@property(nonatomic,copy)NSString * recognizerID;
@property (nonatomic, copy) NSString *destinationLanguageId;
@property (nonatomic, copy) NSString *sourceLanguageId;
@property(nonatomic,assign)id <MSSpeechRecognizerDelegate> delegate;

-(instancetype)initWithDelegate:(id <MSSpeechRecognizerDelegate>)delegate;
-(void)setSourceLanguageId:(NSString *)sourceLanguageId destinationLanguageId:(NSString *)destinationLanguageId direction:(LangDirection)direction;

-(void)configRecord:(OMRecordManager *)record;
-(void)startRecognizer;
-(void)completeRecognizer;
-(void)cancelRecognizer;
@end

NS_ASSUME_NONNULL_END
