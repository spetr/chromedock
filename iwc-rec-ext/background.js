'use strict';

const audioBitsPerSecond = 128000;
const videoBitsPerSecond = 2621440;
const videoCodec = 'H264'; // VP8, VP9, H264
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
                console.log('Error while capturing tab: ' + chrome.runtime.lastError.message);
                console.log('Please run chrome with: --whitelisted-extension-id=' + chrome.runtime.id);
                return;
            }
            console.log('Recieved tabCapture stream:', stream)

            var options = {
                type: 'video',
                disableLogs: true,
                ignoreMutedMedia: true,
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
                    console.log('Unknown video codec');
                    return;
            }

            var mediaRecorder = new MediaRecorder(stream, options);
            var seqID = 0;
            mediaRecorder.ondataavailable = (event) => {
                if (event.data.size > 0) {
                    seqID++;
                    console.log(`Sending chunk ${seqID} to API.`);
                    let xhr = new XMLHttpRequest();
                    let url = apiURL;
                    if (mediaRecorder.state === 'inactive') {
                        url += '?end'
                    }
                    xhr.open('POST', url, true);
                    xhr.timeout = 4500;
                    xhr.setRequestHeader('Content-Type', "video/webm");
                    xhr.setRequestHeader('X-ID', "test.webm");
                    xhr.setRequestHeader('X-SeqID', seqID);
                    xhr.onerror = () => {
                        console.log(`Error while sending chunk ${seqID} to API.`);
                    };
                    xhr.onload = () => {
                        switch (xhr.status) {
                            case 200:
                                console.log(`Succesfuly send chunk ${seqID} to API.`);
                                break;
                            default:
                                console.log(`Recieved enexpected http response ${xht.status} when sending chunk ${seqID} to API.`); 
                        }
                    }
                    xhr.send(event.data);
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

            chrome.tabs.create({active: true, index:0, url: "about:blank"})
        });
    });
};

console.log('iw-conference-recorder-extension loaded');