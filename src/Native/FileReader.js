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

            /*
             * Test for existence of FileRader using
             * if(window.FileReader) { ...
             * http://caniuse.com/#search=filereader
             * main gap is IE10 and 11 which do not support readAsBinaryFile
             * but we do not use this API either as it is deprecated
             */
            var reader = new FileReader();

            reader.onload = function(evt) {
                return callback(Task.succeed(evt.target.result))
            };

            reader.onerror = function() {
                return callback(Task.fail({ctor : 'ReadFail'}));
            };

            // Error if not passed an objectToRead or if it is not a Blob
            if (!fileObjectToRead || !(fileObjectToRead instanceof Blob)) {
                return callback(Task.fail({ctor : 'NoValidBlob'}));
            }

            return reader[method](fileObjectToRead);
        });
    }

    // readAsTextFile : Value -> Task error String
    var readAsTextFile = function(fileObjectToRead){
        return useReader("readAsText", fileObjectToRead);
    };

    // readAsArrayBuffer : Value -> Task error String
    var readAsArrayBuffer = function(fileObjectToRead){
        return useReader("readAsArrayBuffer", fileObjectToRead);
    };

    // readAsDataUrl : Value -> Task error String
    var readAsDataUrl = function(fileObjectToRead){
        return useReader("readAsDataURL", fileObjectToRead);
    };

    var multipart = function(dataList)
    {
    	var formData = new FormData();

    	while (dataList.ctor !== '[]')
    	{
    		var data = dataList._0;
    		if (data.ctor === 'StringPart')
    		{
    			formData.append(data._0, data._1);
    		}
    		else
    		{
    			var fileName = data._1.ctor === 'Nothing'
    				? undefined
    				: data._1._0;
    			formData.append(data._0, data._2, fileName);
                // formData.append(name, value, filename);
    		}
    		dataList = dataList._1;
    	}
        console.log({ ctor: 'FormDataBody', formData: formData });
    	return { ctor: 'FormDataBody', formData: formData };
    };

    var blobPart = function(name, fileName, blob) {
        return {
            ctor: 'Blob',
            _0: name,
            _1: {
                ctor: 'Just',
                _0: fileName
            },
            _2: blob
        }
    };

    return {
        readAsTextFile : readAsTextFile,
        readAsArrayBuffer : readAsArrayBuffer,
        readAsDataUrl: readAsDataUrl,
        multipart: multipart,
        blobPart: F3(blobPart)
    };
};
