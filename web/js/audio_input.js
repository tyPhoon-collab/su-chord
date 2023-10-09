let scriptProcessor;
let source;

let deviceId = null;
let stream = null;

function _onAudioProcess(event) {
    const sampleRate = event.inputBuffer.sampleRate;
    const array = event.inputBuffer.getChannelData(0);
    window.process(array, sampleRate);
    // console.log(array);
}

function _onDeviceChanged(event) {
    getDeviceInfo().then(list => window.onDeviceChanged(list, deviceId));
}

async function setUpStream() {
    const constraints = deviceId == null ? true : {deviceId: deviceId};
    stream = await navigator.mediaDevices.getUserMedia({audio: constraints});
}

async function start(bufferSize) {
    try {
        if (stream == null) {
            await setUpStream();
        }

        const audioContext = new AudioContext();
        source = audioContext.createMediaStreamSource(stream);

        scriptProcessor = audioContext.createScriptProcessor(bufferSize, 1, 1);

        //buffer listener
        scriptProcessor.addEventListener("audioprocess", _onAudioProcess)

        //connect
        source.connect(scriptProcessor);
        scriptProcessor.connect(audioContext.destination);

        //device change listener
        navigator.mediaDevices.addEventListener("devicechange", _onDeviceChanged)
        //call once
        _onDeviceChanged(null)

    } catch (error) {
        console.error("Error accessing the microphone:", error);
    }
}

function stop() {
    stream = null;
    source?.disconnect();
    scriptProcessor?.disconnect();
    scriptProcessor?.removeEventListener("audioprocess", _onAudioProcess);
    navigator.mediaDevices.removeEventListener("devicechange", _onDeviceChanged);
}

async function setDeviceId(id) {
    deviceId = id;
    stop();
    await setUpStream();
    _onDeviceChanged(null);
}

async function getDeviceInfo() {
    const devices = await navigator.mediaDevices.enumerateDevices();
    return devices.filter(device => device.kind === 'audioinput');
}
