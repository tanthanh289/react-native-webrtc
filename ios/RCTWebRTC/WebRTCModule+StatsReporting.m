//
//  WebRTCModule+StatsReporting.m
//  RCTWebRTC
//
//  Created by Tuan Luong on 6/9/20.
//

#import <objc/runtime.h>
#import <WebRTC/RTCLegacyStatsReport.h>

#import "WebRTCModule+StatsReporting.h"
#import "WebRTCModule+RTCPeerConnection.h"

@implementation WebRTCModule (StatsReporting)

- (LocalAudioAnalyzer *)localAudioAnalyzer
{
  return objc_getAssociatedObject(self, _cmd);
}

- (void)setLocalAudioAnalyzer:(LocalAudioAnalyzer *)localAudioAnalyzer
{
  objc_setAssociatedObject(self, @selector(localAudioAnalyzer), localAudioAnalyzer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

RCT_EXPORT_METHOD(startStatsReporting:(float)speakingThreshold) {
  dispatch_sync(dispatch_get_main_queue(), ^{
    if (self.localAudioAnalyzer == nil) {
      self.localAudioAnalyzer = [[LocalAudioAnalyzer alloc] init];
      self.localAudioAnalyzer.delegate = self;
    }
    [self.localAudioAnalyzer start:speakingThreshold];
  });
}

RCT_EXPORT_METHOD(stopStatsReporting) {
  dispatch_sync(dispatch_get_main_queue(), ^{
    [self.localAudioAnalyzer stop];
  });
}

-(void)onSpeak:(BOOL)speaking {
  if (speaking) {
    NSLog(@"Speaking");
    [self sendEventWithName:kEventSpeaking body:nil];
  } else {
    NSLog(@"Stop speaking");
    [self sendEventWithName:kEventStopSpeaking body:nil];
  }
}
@end
