# Elm HTML5 FileReader bindings

Bindings for the [HTML5 file upload control](http://www.w3.org/TR/html-markup/input.file.html), which is implemented in browsers via the native `FileReader` class.

FileReader has three main methods (see [MDN](https://developer.mozilla.org/en/docs/Web/API/FileReader)):

    FileReaderInstance.readAsText();
    FileReaderInstance.readAsArrayBuffer();
    FileReaderInstance.readAsDataURL();

The module also provides helper Elm decoders for `change` events on `<Input type="file">` and `drop` events, together with a set of examples.

Simon Hampton, Daniel Bachler
