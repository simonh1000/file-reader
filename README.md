# Elm HTML5 FileReader bindings

Bindings for the [HTML5 file reader control](http://www.w3.org/TR/html-markup/input.file.html), which is implemented in browsers via the native `FileReader` class.

FileReader has three main methods (see [MDN](https://developer.mozilla.org/en/docs/Web/API/FileReader)):

    FileReaderInstance.readAsText();
    FileReaderInstance.readAsArrayBuffer();
    FileReaderInstance.readAsDataURL();

The module also provides helper Elm json decoders for `change` events on `<Input type="file">` and `drop` events.

=======
**New for Elm 0.18:** An additional native code function has been added to enable multipart form uploads of binary data - see http://simonh1000.github.io/2016/12/elm-s3-uploads/ for an example of its usage.
>>>>>>> master

## Installation

### [elm-github-install](https://github.com/gdotdesign/elm-github-install)

A tool to install native-code based Elm libraries

```
(sudo) gem install elm_install
<add  "simonh1000/file-reader": "1.0.0 <= v < 2.0.0" to the dependencies section of elm-package.json>
elm-install
```

### Manually

You can just copy the src code into your own source tree. Note in particular that you then need to add `"native-modules": true,` to your elm-package.json file as is done in the examples.

## Examples

If you want to try the examples, you will need to edit src/Native/FileReader.js to replace the comments in the first two lines.

## Changelog

1.5: add `onFileChange` - an event handler for an `<input type="file">`

## Disclaimer

This project began in the time of 0.16 and was submitted as a library including "native code" to the elm-package manager by [Daniel Bachler](https://github.com/danyx23) and myself. It was never OKed, as was the case with all native code at that time. The native code was subsequently updated by [WangBoxue](https://github.com/WangBoxue) to work with 0.17, and I ensured it worked for 0.18.

In theory Evan plans to make all browser web APIs available to Elm users and when that includes FileReader, this library will remove the native code. The official guidance therefore is to use a port rather than the native code in this library, but you can readily verify that the native code here covers the absolute minimum to expose the APIs, so I believe this will not jeopardise the stability of your Elm apps.
