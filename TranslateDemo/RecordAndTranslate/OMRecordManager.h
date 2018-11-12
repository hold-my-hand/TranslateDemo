//
//  OMRecordManager.h
//  one mini
//
//  Created by 姜政 on 2018/11/12.
//  Copyright © 2018 te iol8. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN
@protocol OMRecordManagerDelegate <NSObject>

@optional
-(void)didRecordData:(NSData *)pcmData;
-(void)didRecordBuffer:(AudioBuffer)buffer bufferList:(AudioBufferList *)bufferList;
@end

@interface OMRecordManager : NSObject
+(instancetype)shareInstance;
@property(nonatomic,assign)id <OMRecordManagerDelegate> delegate;
- (void)startRecorder;
- (void)stopRecorder;
@end

NS_ASSUME_NONNULL_END
