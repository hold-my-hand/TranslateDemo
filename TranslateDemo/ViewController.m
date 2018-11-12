//
//  ViewController.m
//  TranslateDemo
//
//  Created by 姜政 on 2018/11/12.
//  Copyright © 2018 None. All rights reserved.
//

#import "ViewController.h"
#import "MSSpeechRecognizer.h"

@interface ViewController ()<MSSpeechRecognizerDelegate>

@property(nonatomic,strong)MSSpeechRecognizer *speechRecognizer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
-(MSSpeechRecognizer *)speechRecognizer{
    if (!_speechRecognizer) {
        _speechRecognizer = [[MSSpeechRecognizer alloc] initWithDelegate:self];
        [_speechRecognizer setSourceLanguageId:@"zh-CN" destinationLanguageId:@"en-US" direction:LeftDirection];
        [_speechRecognizer configRecord:[OMRecordManager shareInstance]];
    }
    return _speechRecognizer;
}

- (IBAction)startAsr:(id)sender {
    [self.speechRecognizer startRecognizer];
}

- (IBAction)endAsr:(id)sender {
    [self.speechRecognizer completeRecognizer];
}

-(void)machineTranslator:(NSString *)translation recognition:(NSString *)recognition direction:(LangDirection)direction recognizerID:(NSString *)recognizerID finish:(BOOL)finish{
    NSLog(@"%@,%@",translation,recognition);
}

@end
