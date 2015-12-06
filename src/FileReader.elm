module FileReader
    ( FileRef
    , FileContentArrayBuffer
    , FileContentDataUrl
    , NativeFile
    , Error(..)
    , readAsTextFile
    , readAsArrayBuffer
    , readAsDataUrl
    , toString
    , parseSelectedFiles
    , parseDroppedFiles
    ) where

{-| Elm bindings for HTML5 FileReader API.

# Read file from disk using HTML5 FileReader API.

@docs FileRef, FileContentArrayBuffer, FileContentDataUrlError,
readAsTextFile, readAsArrayBuffer, readAsDataUrl, toString,
parseSelectedFiles, parseDroppedFiles
-}

import Signal
import Task exposing (Task)

import Native.FileReader
import Json.Decode as Json exposing
    (Decoder, Value, (:=), andThen, at, oneOf, succeed,
     object1, object2, object4, string, int, null, value)

import MimeHelpers

{-| Helper aliases

    type alias FileRef = Value
    type alias FileContentArrayBuffer = Value
    type alias FileContentDataUrl = Value
-}
type alias FileRef = Value
type alias FileContentArrayBuffer = Value
type alias FileContentDataUrl = Value

{-| FileReader can fail in one of two cases:

 - the File reference / blob passed in was not valid
 - the Id specified in getTextFile does not match an input of type file in the document
-}
type Error
    = NoValidBlob
    | ReadFail

{-| Takes a "File" or "Blob" JS object as a Json.Value, and
returns a task that reads in the file as a text file. The text vlue returned
in the Success case will be represented as a String to Elm.

    readAsTextFile ref
-}
readAsTextFile : FileRef -> Task Error String
readAsTextFile = Native.FileReader.readAsTextFile

{-| Takes a "File" or "Blob" JS object as a Json.Value
and starts a task to read the contents as an ArrayBuffer.
The ArrayBuffer value returned in the Success case of the Task will
be represented as a Json.Value to Elm.

    readAsArrayBuffer ref
-}
readAsArrayBuffer : FileRef -> Task Error FileContentArrayBuffer
readAsArrayBuffer = Native.FileReader.readAsArrayBuffer

{-| Takes a "File" or "Blob" JS object as a Json.Value
and starts a task to read the contents as an DataURL (so it can
be assigned to the src property of an img e.g.).
The DataURL value returned in the Success case of the Task will
be represented as a Json.Value to Elm.

    readAsDataUrl ref
-}
readAsDataUrl : FileRef -> Task Error FileContentDataUrl
readAsDataUrl = Native.FileReader.readAsDataUrl

{-| Helper function for errors.

    toString ReadFail   -- == "File reading error"
-}
toString : Error -> String
toString err =
    case err of
        ReadFail -> "File reading error"
        NoValidBlob -> "Blob was not valid"

{-| Helper type for interpreting the Files event value from Input and drag 'n drop.
The first three elements are useful meta data, while the fourth is the handle
needed to read the file.

    type alias NativeFile =
        { name : String
        , size : Int
        , mimeType : Maybe MimeHelpers.MimeType
        , blob : Value
        }
-}
type alias NativeFile =
    { name : String
    , size : Int
    , mimeType : Maybe MimeHelpers.MimeType
    , blob : FileRef
    }

{-| Parse change event from an HTML input element with 'type="file"'.
Returns a list of file objects.

    onchange : (List NativeFile -> Action) -> Signal.Address Action -> Html.Attribute
    onchange address actionCreator =
        on
            "change"
            parseSelectedFiles
            (\vals -> Signal.message address (actionCreator vals))
-}
parseSelectedFiles : Decoder (List NativeFile)
parseSelectedFiles =
    eventParser "target"

{-| Parse files selected using an HTML drop event.
Returns a list of file objects.

    ondrop : (List NativeFile -> Action) -> Signal.Address Action -> Html.Attribute
    ondrop actionCreator address =
        onWithOptions
            "drop"
            {stopPropagation = True, preventDefault = True}
            parseDroppedFiles
            (\vals -> Signal.message address (actionCreator vals))

-}
parseDroppedFiles : Decoder (List NativeFile)
parseDroppedFiles =
    eventParser "dataTransfer"

{- Un-exported Helpers

The Files event has a structure

    { 1 : file1..., 2: file2..., 3 : ... }

It also inherits a 'length' property that we read first and use (in parseFiles)
to read the file values themselves
-}
eventParser : String -> Decoder (List NativeFile)
eventParser field =
    at
        [ field, "files" ]
        (filesLength `andThen` parseFiles)

filesLength : Decoder Int
filesLength =
    oneOf
        [ object1 identity ("length" := int)
        , null 0
        ]

parseFiles : Int -> Decoder (List NativeFile)
parseFiles count =
    List.foldl
        (\e -> object2 (::) (fileAt e))
        (succeed [])
        [0 .. count - 1]

fileAt : Int -> Decoder NativeFile
fileAt index =
    (Basics.toString index) := nativeFile

{- mime type: parsed as string and then converted to a MimeType
blob: the whole JS File object as a Json.Value so we can pass
it to a library that reads the content with a native FileReader
-}
nativeFile : Decoder NativeFile
nativeFile =
    object4
        NativeFile
            ("name" := string)
            ("size" := int)
            (object1 MimeHelpers.parseMimeType ("type" := string))
            value
