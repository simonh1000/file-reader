# Elm HTML5 FileReader controls

Implementations for the [HTML5 file upload control](http://www.w3.org/TR/html-markup/input.file.html), which is implemented in browsers via the native `FileReader` class.

    FileReaderInstance.readAsText(fileOrBlob);
    FileReaderInstance.readAsArrayBuffer(fileOrBlob);
    FileReaderInstance.readAsDataURL(fileOrBlob);

    getTextFile : String -> Task Error String

Implementations using file Input types and drag 'n drop are provided in the `examples` directory.
