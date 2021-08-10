'use strict';

const audioBitsPerSecond = 128000;
const videoBitsPerSecond = 2610000;
const videoCodec = 'VP8'; // VP8, VP9, H264
const apiURL = 'http://RECORDING-API/record';

let isRecording = false;

// Listen tab events
chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
    if (tab.active === false) {
        return;
    }
    switch (changeInfo.status) {
        case 'complete':
            var pattern = /^((http|https):\/\/)/;
            if (!pattern.test(tab.url)) {
                console.log('URL of active tab is not starting with http:// or https://')
            } else if (isRecording === true) {
                console.log('Recording is running');
            } else {
                startScreenRecording(tabId);
            }
            break;
        default:
    }
});

// Start recording (current tab)
function startScreenRecording(tabId) {
    console.log('Starting tab recording.')
    chrome.tabs.update(tabId, {
        muted: true,
        active: true
    }, () => {
        var constraints = {
            audio: true,
            video: true,
            audioConstraints: {
                mandatory: {
                    echoCancellation: false
                }
            },
            videoConstraints: {
                mandatory: {
                    chromeMediaSource: 'tab',
                    minWidth: 16,
                    minHeight: 9,
                    maxWidth: 1920,
                    maxHeight: 1080,
                    maxFrameRate: 15
                }
            }
        };
        chrome.tabCapture.capture(constraints, (stream) => {
            if (chrome.runtime.lastError) {
                console.log('Error while capturing tab.');
                console.log(chrome.runtime.lastError.message);
                console.log('Please run chrome with: --whitelisted-extension-id=' + chrome.runtime.id);
                return;
            }
            console.log('Recieved tabCapture stream:', stream)

            var recStream = new MediaStream();
            stream.getTracks().forEach((track) => {
                recStream.addTrack(track);
            });

            var options = {
                type: 'video',
                disableLogs: false,
                ignoreMutedMedia: false,
                audioBitsPerSecond: audioBitsPerSecond,
                videoBitsPerSecond: videoBitsPerSecond,
            };
            switch (videoCodec) {
                case 'VP8':
                    options.mimeType = 'video/webm; codecs="vp8, opus"';
                    break;
                case 'VP9':
                    options.mimeType = 'video/webm; codecs="vp9, opus"';
                    break;
                case 'H264':
                    options.mimeType = 'video/webm; codecs="h264, opus"';
                    break;
                default:
                    console.log("Unknown video codec");
                    return;
            }

            var mediaRecorder = new MediaRecorder(recStream, options);
            var seqID = 0;
            mediaRecorder.ondataavailable = (event) => {
                if (event.data.size > 0) {
                    seqID++;
                    console.log(`Sending chunk ${seqID} to API.`);
                    console.log(mediaRecorder.state);
                    var xhr = new XMLHttpRequest();
                    var url = apiURL;
                    if (mediaRecorder.state === 'inactive') {
                        url += '?end'
                    }
                    xhr.open('POST', url, true);
                    xhr.setRequestHeader('Content-Type', "video/webm");
                    xhr.setRequestHeader('X-ID', "test.webm");
                    xhr.setRequestHeader('X-SeqID', seqID);
                    xhr.send(event.data);
                    xhr.onreadystatechange = () => {
                        if (xhr.readyState === XMLHttpRequest.DONE) {
                            if (xhr.status === 200) {
                                console.log(`Succesfuly send chunk ${seqID} to API.`);
                                return
                            }
                            console.log(`Error while sending chunk ${seqID} to API.`);
                            console.log(xhr);
                        }
                    }
                }
            };
            mediaRecorder.onerror = (event) => {
                console.log('Media recorder error.');
                console.log(event);
                isRecording = false;
                mediaRecorder.stop();
            };
            mediaRecorder.onstop = (event) => {
                console.log('Media recorder stop.');
                console.log(event);
                isRecording = false;
            };

            mediaRecorder.start(5000);
            isRecording = true;
        });
    });
};

console.log('iw-conference-recorder-extension loaded');
