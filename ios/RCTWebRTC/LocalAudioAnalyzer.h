//
//  LocalAudioAnalyzer.h
//  RCTWebRTC
//
//  Created by Tuan Luong on 6/18/20.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol LocalAudioAnalyzerDelegate <NSObject>
- (void)onSpeak:(BOOL)speaking;

@end

@interface LocalAudioAnalyzer : NSObject<AVAudioRecorderDelegate>

@property (nonatomic, weak) id<LocalAudioAnalyzerDelegate> delegate;

-(void)start:(float)speakingThreshold;
-(void)stop;

@end
