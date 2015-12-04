Elm.Native = Elm.Native || {};
Elm.Native.FileReader = {};

Elm.Native.FileReader.make = function(localRuntime){

    localRuntime.Native = localRuntime.Native || {};
    localRuntime.Native.FileReader = localRuntime.Native.FileReader || {};

    if (localRuntime.Native.FileReader.values){
        return localRuntime.Native.FileReader.values;
    }

    var Task = Elm.Native.Task.make(localRuntime);

    // getTextFile : String -> Task error String
    var getTextFile = function(id){
        var inputId = document.getElementById(id);
        return readAsTextFile(inputId.files[0]);
    };

    // readAsTextFile : Value -> Task error String
    var readAsTextFile = function(fileObjectToRead){
        return Task.asyncFunction(function(callback){
            var reader = new FileReader();

            reader.onload = function(evt) {
                return callback(Task.succeed(evt.target.result))
            };

            reader.onerror = function() {
                return callback(Task.fail({ctor : 'ReadFail'}));
            };

            if (!fileObjectToRead || !(fileObjectToRead instanceof Blob)) {
                return callback(Task.fail({ctor : 'NoValidBlob'}))
            }

            reader.readAsText(fileObjectToRead);
        });
    };

    // readAsArrayBuffer : Value -> Task error String
    var readAsArrayBuffer = function(fileObjectToRead){
        return Task.asyncFunction(function(callback){
            var reader = new FileReader();

            reader.onload = function(evt) {
                return callback(Task.succeed(evt.target.result))
            };

            reader.onerror = function() {
                return callback(Task.fail({ctor : 'ReadFail'}));
            };

            // specified field must be an <input type='file' ...>
            // so it must exist and
            // it must have a .files element
            if (!fileObjectToRead || !(fileObjectToRead instanceof Blob)) {
                return callback(Task.fail({ctor : 'NoValidBlob'}))
            }

            reader.readAsArrayBuffer(fileObjectToRead);
        });
    };

    // readAsDataUrl : Value -> Task error String
    var readAsDataUrl = function(fileObjectToRead){
        return Task.asyncFunction(function(callback){
            var reader = new FileReader();

            reader.onload = function(evt) {
                return callback(Task.succeed(evt.target.result))
            };

            reader.onerror = function() {
                return callback(Task.fail({ctor : 'ReadFail'}));
            };

            // specified field must be an <input type='file' ...>
            // so it must exist and
            // it must have a .files element
            if (!fileObjectToRead || !(fileObjectToRead instanceof Blob)) {
                return callback(Task.fail({ctor : 'NoValidBlob'}))
            }

            reader.readAsDataURL(fileObjectToRead);
        });
    };


    return {
        getTextFile : getTextFile,
        readAsTextFile : readAsTextFile,
        readAsArrayBuffer : readAsArrayBuffer,
        readAsDataUrl: readAsDataUrl
    };
};
