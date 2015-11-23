Elm.Native = Elm.Native || {};
Elm.Native.FileReader = {};

Elm.Native.FileReader.make = function(localRuntime){

    localRuntime.Native = localRuntime.Native || {};
    localRuntime.Native.FileReader = localRuntime.Native.FileReader || {};

    if (localRuntime.Native.FileReader.values){
        return localRuntime.Native.FileReader.values;
    }

    var Task = Elm.Native.Task.make(localRuntime);

    // getFileContents : String -> Task error String
    var getTextFile = function(id){
        return Task.asyncFunction(function(callback){
            var reader = new FileReader();

            reader.onload = function(evt) {
                return callback(Task.succeed(evt.target.result))
            };

            reader.onerror = function() {
                return callback(Task.fail({ctor : 'ReadFail'}));
            };

            var inputId = document.getElementById(id);
            // specified field must be an <input type='file' ...>
            // so it must exist and
            // it must have a .files element
            if (!inputId || typeof inputId.files != 'object') {
                return callback(Task.fail({ctor : 'IdNotFound'}))
            }

            var fileUpload = inputId.files[0];
            if (fileUpload)
                reader.readAsText(fileUpload);
            else callback(Task.fail({ctor : 'NoFileSpecified'}));
        });
    };

    return {
        getTextFile : getTextFile
    };
};
