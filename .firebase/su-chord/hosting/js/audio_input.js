let scriptProcessor;
let source;
let audioContext = null;
let deviceId = null;
let stream = null;

function _onAudioProcess(event) {
    const sampleRate = event.inputBuffer.sampleRate;
    const array = event.inputBuffer.getChannelData(0);
    window.process(array, sampleRate);
    // console.log(array);
}

function _onDeviceChanged(_) {
    getDeviceInfo().then(list => {
        console.log(`device changed: ${list}`);
        return window.onDeviceChanged(list, deviceId);
    });
}

async function setUpStream() {
    const constraints = deviceId == null ? true : {deviceId: deviceId};
    stream = await navigator.mediaDevices.getUserMedia({audio: constraints});
}

async function start(bufferSize) {
    try {
        if (stream == null) {
            await request();
        }

        audioContext = new AudioContext();
        source = audioContext.createMediaStreamSource(stream);

        scriptProcessor = audioContext.createScriptProcessor(bufferSize, 1, 1);

        //buffer listener
        scriptProcessor.addEventListener("audioprocess", _onAudioProcess)

        //connect
        source.connect(scriptProcessor);
        scriptProcessor.connect(audioContext.destination);


    } catch (error) {
        console.error("Error accessing the microphone:", error);
    }
}

function stop() {
    stream = null;
    audioContext?.close().then(() => audioContext = null);
    source?.disconnect();
    scriptProcessor?.disconnect();
    scriptProcessor?.removeEventListener("audioprocess", _onAudioProcess);
    navigator.mediaDevices.removeEventListener("devicechange", _onDeviceChanged);
}

async function request() {
    await setUpStream();
    navigator.mediaDevices.removeEventListener("devicechange", _onDeviceChanged);
    //device change listener
    navigator.mediaDevices.addEventListener("devicechange", _onDeviceChanged)
    //call once
    _onDeviceChanged(null)
}

async function setDeviceId(id) {
    stop();
    deviceId = id;
    _onDeviceChanged(null);
}

async function getDeviceInfo() {
    const devices = await navigator.mediaDevices.enumerateDevices();
    return devices.filter(device => device.kind === 'audioinput');
}
