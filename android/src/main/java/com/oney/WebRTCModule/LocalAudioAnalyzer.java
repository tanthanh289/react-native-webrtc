package com.oney.WebRTCModule;

import android.util.Log;

import org.webrtc.audio.JavaAudioDeviceModule;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

import io.reactivex.Observer;
import io.reactivex.disposables.Disposable;
import io.reactivex.functions.Action;
import io.reactivex.subjects.PublishSubject;

class LocalAudioAnalyzer implements JavaAudioDeviceModule.SamplesReadyCallback {
    private static final String TAG = "LocalAudioAnalyzer";
    private AtomicBoolean isRunning = new AtomicBoolean(false);
    private boolean isSpeaking = false;
    private LocalAudioAnalyzerCallback callback;
    private long lastSpoke = 0;
    private float speakingThreshold;


    PublishSubject<JavaAudioDeviceModule.AudioSamples> subject;

    /**
     * Should be called on the same executor thread as the one provided at
     * construction.
     */
    public void start(float threshold, LocalAudioAnalyzerCallback callback) {
        subject = PublishSubject.create();
        subject.throttleLast(500, TimeUnit.MILLISECONDS)
                .subscribe(new Observer<JavaAudioDeviceModule.AudioSamples>() {
                    @Override
                    public void onSubscribe(Disposable d) {

                    }

                    @Override
                    public void onNext(JavaAudioDeviceModule.AudioSamples audioSamples) {

                        calculatePeakAndRms(encodeToSample(audioSamples.getData(), audioSamples.getData().length));
                    }

                    @Override
                    public void onError(Throwable e) {

                    }

                    @Override
                    public void onComplete() {

                    }
                });

        Log.d(TAG, "start");
        speakingThreshold = threshold;
        isRunning.set(true);
        this.callback = callback;

    }

    /**
     * Should be called on the same executor thread as the one provided at
     * construction.
     */
    public void stop() {
        Log.d(TAG, "stop");
        isRunning.set(false);
        this.callback = null;
        if(subject != null){
            subject.onComplete();
            subject = null;
        }

    }


    long lastProcessTime = 0;
    @Override
    public void onWebRtcAudioRecordSamplesReady(JavaAudioDeviceModule.AudioSamples audioSamples) {
        if (!isRunning.get()) {
            return;
        }
        //Log.d(TAG, "new audio sample:"+ audioSamples.getData().length);
        subject.onNext(audioSamples);

    }

    private short[] encodeToSample(byte[] srcBuffer, int numBytes) {
        byte[] tempBuffer = new byte[2];
        int nSamples = numBytes / 2;
        short[] samples = new short[nSamples];  // 16-bit signed value

        for (int i = 0; i < nSamples; i++) {
            tempBuffer[0] = srcBuffer[2 * i];
            tempBuffer[1] = srcBuffer[2 * i + 1];
            samples[i] = bytesToShort(tempBuffer);
        }

        return samples;
    }

    private short bytesToShort(byte [] buffer) {
        ByteBuffer bb = ByteBuffer.allocate(2);
        bb.order(ByteOrder.BIG_ENDIAN);
        bb.put(buffer[0]);
        bb.put(buffer[1]);
        return bb.getShort(0);
    }

    /**
     * https://support.biamp.com/General/Audio/Peak_vs_RMS_Meters
     * @param samples
     */
    private void calculatePeakAndRms(short[] samples) {
        double sumOfSampleSq = 0.0;    // sum of square of normalized samples.
        double peakSample = 0.0;     // peak sample.

        for (short sample : samples) {
            double normSample = (double) sample / 32767;  // normalized the sample with maximum value.
            sumOfSampleSq += (normSample * normSample);
            if (Math.abs(sample) > peakSample) {
                peakSample = Math.abs(sample);
            }
        }

        double rms = 10*Math.log10(sumOfSampleSq / samples.length);
        double peak = 20*Math.log10(peakSample / 32767);

        if (this.callback != null) {
            boolean speaking = rms > speakingThreshold;
            updateValue(speaking);
        }
    }

    private void updateValue(boolean isSpeaking) {
        //Log.d(TAG, "------PROCESS audio sample:"+isSpeaking);
        if (isSpeaking) {
            if (!this.isSpeaking) {

                this.callback.onSpeaking(true);
            }
            lastSpoke = System.currentTimeMillis();
        } else {
            long diff = System.currentTimeMillis() - lastSpoke;
            if (diff < 300) {
                return;
            }
            if (this.isSpeaking) {
                this.callback.onSpeaking(false);
            }
        }
        this.isSpeaking = isSpeaking;
    }

    interface LocalAudioAnalyzerCallback {
        void onSpeaking(boolean speaking);
    }
}
