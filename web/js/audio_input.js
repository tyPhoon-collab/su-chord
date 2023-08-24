let scriptProcessor;
let source;

function _onAudioProcess(event) {
    const sampleRate = event.inputBuffer.sampleRate;
    const array = event.inputBuffer.getChannelData(0);
    window.process(array, sampleRate);
    // console.log(array);
}

async function start(bufferSize) {
    try {
        const stream = await navigator.mediaDevices.getUserMedia({audio: true});
        const audioContext = new AudioContext();
        source = audioContext.createMediaStreamSource(stream);

        scriptProcessor = audioContext.createScriptProcessor(bufferSize, 1, 1);

        scriptProcessor.addEventListener("audioprocess", _onAudioProcess)

        source.connect(scriptProcessor);
        scriptProcessor.connect(audioContext.destination);
    } catch (error) {
        console.error("Error accessing the microphone:", error);
    }
}

function stop() {
    source?.disconnect();
    scriptProcessor?.disconnect();
    scriptProcessor?.removeEventListener("audioprocess", _onAudioProcess);
}
