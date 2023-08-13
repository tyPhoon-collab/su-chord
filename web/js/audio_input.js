"use strict";

// Web用のマイクの入力を管理する関数群
let audioBuffer = [];
let recorder = undefined;

function startRec(bufferSize, sampleRate = 22050) {
    navigator.mediaDevices
        .getUserMedia({audio: true, video: false})
        .then((stream) => {
            recorder = new MediaRecorder(stream);
            recorder.ondataavailable = (event) => {
                audioBuffer.push(event.data);
            }

            recorder.start(1000);
        })
        .catch((err) => {
            console.log(err);
        });
}

function getAudioBuffer() {
    let blob = new Blob(audioBuffer);
    console.log(blob);
}

function stopRec() {
    recorder.stop();
}
