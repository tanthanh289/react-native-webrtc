//
//  LocalAudioAnalyzer.m
//  RCTWebRTC
//
//  Created by Tuan Luong on 6/18/20.
//

#import "LocalAudioAnalyzer.h"

@implementation LocalAudioAnalyzer {
  AVAudioRecorder *_audioRecorder;
  id _progressUpdateTimer;
  int _progressUpdateInterval;
  NSDate *_prevProgressUpdateTime;
  AVAudioSession *_recordSession;
  BOOL isSpeaking;
  float speakingThreshold;
}

-(void)start:(float)threshold
{
  NSLog(@"Start Monitoring");
  _prevProgressUpdateTime = nil;
  _progressUpdateInterval = 500;
  speakingThreshold = threshold;
  [self stopProgressTimer];
  
  NSDictionary *recordSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInt:AVAudioQualityLow], AVEncoderAudioQualityKey,
                                  [NSNumber numberWithInt:kAudioFormatMPEG4AAC], AVFormatIDKey,
                                  [NSNumber numberWithInt:1], AVNumberOfChannelsKey,
                                  [NSNumber numberWithFloat:22050.0], AVSampleRateKey,
                                  nil];
  
  NSError *error = nil;
  
  _recordSession = [AVAudioSession sharedInstance];
  [_recordSession setCategory:AVAudioSessionCategoryMultiRoute error:nil];
  
  NSURL *_tempFileUrl = [NSURL fileURLWithPath:@"/dev/null"];
  
  _audioRecorder = [[AVAudioRecorder alloc]
                    initWithURL:_tempFileUrl
                    settings:recordSettings
                    error:&error];
  
  _audioRecorder.delegate = self;
  
  if (error) {
    NSLog(@"error: %@", [error localizedDescription]);
  } else {
    [_audioRecorder prepareToRecord];
  }
  
  _audioRecorder.meteringEnabled = YES;
  
  [self startProgressTimer];
  [_recordSession setActive:YES error:nil];
  [_audioRecorder record];
}

- (void)sendProgressUpdate {
  if (!_audioRecorder || !_audioRecorder.isRecording) {
    return;
  }
  
  if (_prevProgressUpdateTime == nil
      || (([_prevProgressUpdateTime timeIntervalSinceNow] * -1000.0) >= _progressUpdateInterval)) {
    [_audioRecorder updateMeters];
    float _currentLevel = [_audioRecorder averagePowerForChannel: 0];
//    NSLog(@"currentlevel %f %d", [_prevProgressUpdateTime timeIntervalSinceNow],_progressUpdateInterval);
    BOOL speaking = _currentLevel > speakingThreshold;
    if (speaking != isSpeaking) {
      if ([self.delegate respondsToSelector:@selector(onSpeak:)]) {
        [self.delegate onSpeak:speaking];
      }
    }
    isSpeaking = speaking;
    _prevProgressUpdateTime = [NSDate date];
  }
}

-(void)stop
{
  [_audioRecorder stop];
  [_recordSession setCategory:AVAudioSessionCategoryPlayback error:nil];
  _prevProgressUpdateTime = nil;
}

- (void)stopProgressTimer {
  [_progressUpdateTimer invalidate];
}

- (void)startProgressTimer {
  [self stopProgressTimer];
  
  _progressUpdateTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(sendProgressUpdate)];
  [_progressUpdateTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

@end
