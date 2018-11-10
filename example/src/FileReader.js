export function dispatcher(data, callback) {
    switch (data.tag) {
        case "readAsText":
            useReader("readAsText", data.payload.blob, result => {
                let obj = Object.assign({tag: data.payload.tag}, {payload: result});
                console.log(obj);
                callback(obj);
            })
            break
        case "readAsDataUrl":
            break
        default:
            callback(data.payload = {error: "UnrecognisedTag"});
    }
}


function useReader(method, fileObjectToRead, callback) {
    /*
         * Test for existence of FileReader using
         * if(window.FileReader) { ...
         * http://caniuse.com/#search=filereader
         * main gap is IE10 and 11 which do not support readAsBinaryFile
         * but we do not use this API either as it is deprecated
         */
    var reader = new FileReader();

    reader.onload = function(evt) {
        return callback({data: evt.target.result});
    };

    reader.onerror = function() {
        return callback({ error: "ReadFail" });
    };

    // Error if not passed an objectToRead or if it is not a Blob
    if (!fileObjectToRead || !(fileObjectToRead instanceof Blob)) {
        return callback({ error: "NoValidBlob" });
    }

    if (reader[method]) {
        var result = reader[method](fileObjectToRead);
        // prevent memory leak by nullifying fileObjectToRead
        fileObjectToRead = null;
        return result;
    } else {
        return callback({ ctor: "ReadFail" });
    }
}

// readAsTextFile : Value -> Task error String
function readAsTextFile(fileObjectToRead) {
    return useReader("readAsText", fileObjectToRead);
}

// readAsArrayBuffer : Value -> Task error String
function readAsArrayBuffer(fileObjectToRead) {
    return useReader("readAsArrayBuffer", fileObjectToRead);
}

// readAsDataUrl : Value -> Task error String
function readAsDataUrl(fileObjectToRead) {
    return useReader("readAsDataURL", fileObjectToRead);
}

// var filePart = function(name, blob) {
//     return {
//         _0: name,
//         _1: blob
//     }
// };
//
// var rawBody = function (mimeType, blob) {
//     return {
//         ctor: "StringBody",
//         _0: mimeType,
//         _1: blob
//     };
// };
