# Elm HTML5 file upload control

Elm does not currently include the [HTML5 file upload control](http://www.w3.org/TR/html-markup/input.file.html), which is implemented in browsers via `FileReader`.

This package addresses that shortfall with a Native code library and Elm code exposing an Error Type and function that takes the `id` of an input control.

    getTextFile : String -> Task Error String

See it in action in the `examples` directory.
