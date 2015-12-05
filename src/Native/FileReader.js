Elm.Native = Elm.Native || {};
Elm.Native.FileReader = {};

Elm.Native.FileReader.make = function(localRuntime){

    localRuntime.Native = localRuntime.Native || {};
    localRuntime.Native.FileReader = localRuntime.Native.FileReader || {};

    if (localRuntime.Native.FileReader.values){
        return localRuntime.Native.FileReader.values;
    }

    var Task = Elm.Native.Task.make(localRuntime);

    function useReader(method, fileObjectToRead) {
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

            reader[method](fileObjectToRead);
        });
    }

    // readAsTextFile : Value -> Task error String
    var readAsTextFile = function(fileObjectToRead){
        return useReader("readAsText", fileObjectToRead);
    };

    // readAsArrayBuffer : Value -> Task error String
    var readAsArrayBuffer = function(fileObjectToRead){
        return useReader("readAsArrayBuffer", fileObjectToRead);
        // return Task.asyncFunction(function(callback){
        //     var reader = new FileReader();
        //
        //     reader.onload = function(evt) {
        //         return callback(Task.succeed(evt.target.result))
        //     };
        //
        //     reader.onerror = function() {
        //         return callback(Task.fail({ctor : 'ReadFail'}));
        //     };
        //
        //     // specified field must be an <input type='file' ...>
        //     // so it must exist and
        //     // it must have a .files element
        //     if (!fileObjectToRead || !(fileObjectToRead instanceof Blob)) {
        //         return callback(Task.fail({ctor : 'NoValidBlob'}))
        //     }
        //
        //     reader.readAsArrayBuffer(fileObjectToRead);
        // });
    };

    // readAsDataUrl : Value -> Task error String
    var readAsDataUrl = function(fileObjectToRead){
        return useReader("readAsDataURL", fileObjectToRead);
        // return Task.asyncFunction(function(callback){
        //     var reader = new FileReader();
        //
        //     reader.onload = function(evt) {
        //         return callback(Task.succeed(evt.target.result))
        //     };
        //
        //     reader.onerror = function() {
        //         return callback(Task.fail({ctor : 'ReadFail'}));
        //     };
        //
        //     // specified field must be an <input type='file' ...>
        //     // so it must exist and
        //     // it must have a .files element
        //     if (!fileObjectToRead || !(fileObjectToRead instanceof Blob)) {
        //         return callback(Task.fail({ctor : 'NoValidBlob'}))
        //     }
        //
        //     reader.readAsDataURL(fileObjectToRead);
        // });
    };


    return {
        readAsTextFile : readAsTextFile,
        readAsArrayBuffer : readAsArrayBuffer,
        readAsDataUrl: readAsDataUrl
    };
};
