//
// Source code recreated from a .class file by IntelliJ IDEA // (powered by Fernflower decompiler)
//

package org.cocos2dx.javascript;

import android.app.Activity;
import android.content.Context;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.media.MediaRecorder;
import android.media.MediaPlayer.OnCompletionListener;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.util.Log;
import android.widget.Toast;
import java.io.File;
import java.io.IOException;

public class RecordAndPlayHelper {
    private static MediaRecorder mRecorder = null;
    private static MediaPlayer mediaPlayer = null;
    private static boolean isRecording = false;
    public RecordAndPlayHelper() { }
    public static void stopPlayVoice() {
        Log.e("RecordAndPlayHelper", "stopPlayVoice");
        if (mediaPlayer != null && mediaPlayer.isPlaying()) {
            mediaPlayer.stop();
            mediaPlayer.release();
            mediaPlayer = null;
        }
    }
    public static int playVoice(String filePath) {
        Log.e("RecordAndPlayHelper", "playVoice:" + filePath);
        if ((new File(filePath)).exists()) {
            AudioManager audioManager = (AudioManager)AppActivity.getContext().getSystemService(Context.AUDIO_SERVICE);
            audioManager.setMode(audioManager.MODE_NORMAL);
            audioManager.setSpeakerphoneOn(true);
            mediaPlayer = new MediaPlayer();
            mediaPlayer.setAudioStreamType(audioManager.STREAM_MUSIC);
            try {
                mediaPlayer.setDataSource(filePath);
                mediaPlayer.prepare();
                mediaPlayer.setOnCompletionListener(
                        new OnCompletionListener() {
                            public void onCompletion(MediaPlayer mp) {
                                RecordAndPlayHelper.stopPlayVoice();
                            }
                        });
                mediaPlayer.start();
            } catch (Exception var3) {
                var3.printStackTrace();
            }
            return audioManager.getStreamVolume(audioManager.STREAM_MUSIC);
        }
        return 0;
    }
    public static boolean startRecord(String filepath) {
        if (checkRecordPermision()) {
            realRecord(filepath);
            return true;
        } else {
            return false;
        }
    }
    public static void realRecord(String filepath) {
        Log.e("RecordAndPlayHelper", "startRecord");
        Log.e("RecordAndPlayHelper", filepath);
        try {
            if (mRecorder != null) {
                mRecorder.release();
                mRecorder = null;
            }
            mRecorder = new MediaRecorder();
            mRecorder.setAudioSource(1);
            mRecorder.setOutputFormat(3);
            mRecorder.setAudioEncoder(1);
            mRecorder.setAudioChannels(1);
            mRecorder.setAudioSamplingRate(8000);
            mRecorder.setAudioEncodingBitRate(64);
            mRecorder.setOutputFile(filepath);
            mRecorder.prepare();
            isRecording = true;
            mRecorder.start();
        } catch (IOException var2) {
            Log.e("RecordAndPlayHelper", var2.toString());
        }
    }
    public static boolean checkRecordPermision() {
        if (ContextCompat.checkSelfPermission(AppActivity.getContext(), "android.permission.RECORD_AUDIO") != 0) {
            if (ActivityCompat.shouldShowRequestPermissionRationale((Activity)AppActivity.getContext(),
                    "android.permission.RECORD_AUDIO")) {
                ((AppActivity)AppActivity.getContext()).runOnUiThread(
                        new Runnable() {
                            public void run() {
                                Toast.makeText(AppActivity.getContext(), "您已禁⽌止该权限，需要重新开启。", Toast.LENGTH_SHORT).show();
                            }
                        });
            } else {
                ((AppActivity)AppActivity.getContext()).runOnUiThread(
                        new Runnable() {
                            public void run() {
                                ActivityCompat.requestPermissions((Activity)AppActivity.getContext(),
                                        new String[]{"android.permission.RECORD_AUDIO"},
                                        100);
                            }
                        });
            }
            Log.e("RecordAndPlayHelper", "checkRecordPermision false");
            return false;
        } else {
            Log.e("RecordAndPlayHelper", "checkRecordPermision true");
            return true;
        }
    }
    public static int getDB() {
        Log.e("RecordAndPlayHelper", "getDB");
        return mRecorder != null ? (int)((double)mRecorder.getMaxAmplitude() * 20.0D / 32767.0D) : -1;
    }
    public static void stopRecord() {
        Log.e("RecordAndPlayHelper", "stopRecord");
        if (mRecorder != null) {
            try {
                isRecording = false;
                mRecorder.stop();
                mRecorder.reset();
                mRecorder.release();
                mRecorder = null;
            } catch (RuntimeException var1) {
                isRecording = false;
                mRecorder.reset();
                mRecorder.release();
                mRecorder = null;
            }
        }
    }
    public static String getSdCardFile() {
        return AppActivity.getContext().getExternalCacheDir().getAbsolutePath();
    }
}
