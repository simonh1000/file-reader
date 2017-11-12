# Read files into Elm apps

There are two basic ways to read files from the host operating system into the browser (either to view directly or to upload to a server):

- HTML5 FileReader bindings
- drag 'n drop into a target DOM element

This helps with both methods and, in particular provides native bindings for the [HTML5 file reader control](http://www.w3.org/TR/html-markup/input.file.html) (the JS `FileReader` class).

FileReader has three main methods (see [MDN](https://developer.mozilla.org/en/docs/Web/API/FileReader)):

    FileReaderInstance.readAsText();
    FileReaderInstance.readAsArrayBuffer();
    FileReaderInstance.readAsDataURL();

The module also provides helper Elm json decoders for `change` events on `<Input type="file">` and for relevant `drag` and `drop` events.

## Installation

Due to the native (kernel) code, it is not possible to install directly using `elm-package install`. So you need on eof the following methods

### [elm-github-install](https://github.com/gdotdesign/elm-github-install)

A tool to install native-code based Elm libraries

Change you package.json file to readAsDataURL

```
"dependencies": {
    "elm-lang/core": "5.0.0 <= v < 6.0.0",
    "elm-lang/html": "2.0.0 <= v < 3.0.0",
    [....],
    "simonh1000/file-reader": "1.6.0 <= v < 2.0.0"
},
```

```
(sudo) gem install elm_install
elm-install
```

### Manually

You can just copy the src code into your own source tree. Note in particular that you then need to add `"native-modules": true,` to your elm-package.json file as is done in the examples.

## Example

The example provides a fully worked through file upload interface, taking advantage of most of the key functions in this library. If you want to try it, you must *first* edit src/Native/FileReader.js to swap the comments in the first two lines.

## Changelog

1.6: add drag and drop support
1.5: no new functionality
1.4: add `onFileChange` - an event handler for an `<input type="file">`
1.3.1: add rawBody
1.1: Update to 0.18. An additional native code function has been added to enable multipart form uploads of binary data - see http://simonh1000.github.io/2016/12/elm-s3-uploads/ for an example of its usage.

## Disclaimer

This project began in the time of 0.16 and was submitted as a library including "native code" to the elm-package manager by [Daniel Bachler](https://github.com/danyx23) and myself. It was never OKed, as was the case with all native code at that time. The native code was subsequently updated by [WangBoxue](https://github.com/WangBoxue) to work with 0.17, and I ensured it worked for 0.18.

In theory Evan plans to make all browser web APIs available to Elm users, and when that includes FileReader, this library will remove the native code. The official guidance therefore is to use a port rather than the native code in this library, but you can readily verify that the native code here covers the absolute minimum to expose the APIs, so I believe this will not jeopardise the stability of your Elm apps.
