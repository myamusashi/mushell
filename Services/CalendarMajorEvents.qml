pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Helpers

Singleton {
    id: root

    readonly property date currentDate: new Date()

    function sendRequest(url, callback) {
        let request = new XMLHttpRequest();
        request.onreadystatechange = function () {
            if (request.readyState === XMLHttpRequest.DONE) {
                let response = {
                    "status": request.status,
                    "headers": request.getAllResponseHeaders(),
                    "contentType": request.responseType,
                    "content": request.response
                };
                callback(response);
            }
        };
        request.open("GET", url);
        request.send();
    }

    function fetchData(url, onSuccess, onError) {
        sendRequest(url, function (response) {
            if (response.status === 200) {
                try {
                    const json = JSON.parse(response.content);
                    onSuccess(json);
                } catch (e) {
                    if (onError)
                        onError("Failed to parse JSON", e);
                    else
                        console.error("Failed to parse JSON:", e);
                }
            } else {
                if (onError)
                    onError("Request failed", response.status);
                else
                    console.error("Request failed with status:", response.status);
            }
        });
    }

    FileView {
        id: file

        path: Paths.cacheDir + "/events/events.json"
        watchChanges: true
        blockLoading: true
        blockWrites: true
        onFileChanged: reload()
        onAdapterChanged: writeAdapter()

        JsonAdapter {
            id: adapter

            property JsonObject subObject: JsonObject {
                property string subObjectProperty: "default value"
            }
        }
    }
}
