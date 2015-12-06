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

{-| Elm bindings to HTML5 Reader API.

# Read file as text string
@docs Error, readAsTextFile, readAsArrayBuffer, readAsDataUrl

-}

import Signal
import Task exposing (Task)

import Native.FileReader
import Json.Decode as Json exposing
    (Decoder, Value, (:=), andThen, at, oneOf, succeed,
     object1, object2, object4, string, int, null, value)
import MimeHelpers

type alias FileRef = Value
type alias FileContentArrayBuffer = Value
type alias FileContentDataUrl = Value
{-| FileReader can fail in one of four cases:

 - the Id specified in getTextFile does not match an input of type file in the document
 - the blob passed in was not valid
 - no file has been chosen
 - the contents of the file cannot be read.
-}
type Error
    = NoValidBlob
    | ReadFail
    -- | IdNotFound
    -- | NoFileSpecified

{-| Takes the id of an `input` of `type="file"` and attempts
to read the text file associated with it by the user.

    getTextFile "upload"
-}
-- getTextFile : String -> Task Error String
-- getTextFile = Native.FileReader.getTextFile


{-| TBD.

    readAsTextFile val
-}
readAsTextFile : FileRef -> Task Error String
readAsTextFile = Native.FileReader.readAsTextFile

{-| Takes a "File" or "Blob" JS object as a Json.Value
and starts a task to read the contents as an ArrayBuffer.
The ArrayBuffer value returned in the Success case of the Task will
be represented as a Json.Value to Elm.

    readAsArrayBuffer val
-}
readAsArrayBuffer : FileRef -> Task Error FileContentArrayBuffer
readAsArrayBuffer = Native.FileReader.readAsArrayBuffer

{-| Takes a "File" or "Blob" JS object as a Json.Value
and starts a task to read the contents as an DataURL (so it can
be assigned to the src property of an img e.g.).
The DataURL value returned in the Success case of the Task will
be represented as a Json.Value to Elm.

    readAsDataUrl val
-}
readAsDataUrl : FileRef -> Task Error FileContentDataUrl
readAsDataUrl = Native.FileReader.readAsDataUrl


toString : Error -> String
toString err =
    case err of
        ReadFail -> "File reading error"
        NoValidBlob -> "Blob was not valid"


{-| Helper type for the File JS event object resulting
from file select and drag 'n drop. The first three elements are
useful meta data, while the fourth is the handle needed to read
the file

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
{-|
-}
parseSelectedFiles : Decoder (List NativeFile)
parseSelectedFiles =
    eventParser "target"

{-|
-}
parseDroppedFiles : Decoder (List NativeFile)
parseDroppedFiles =
    eventParser "dataTransfer"

-- Unexported Helpers
-- Json decoders for the somewhat weird drop eventdata structure. the .dataTransfer.files property is a JS FileList object which is not an array so cannot
-- be parsed with array, but has to be accessed in the form .dataTransfer.files[index]. This hopefully explains the strange (toString index)
-- way to get a file at an index
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

nativeFile : Decoder NativeFile
nativeFile =
    object4
        NativeFile
            ("name" := string) -- name
            ("size" := int) -- size
            (object1 MimeHelpers.parseMimeType ("type" := string)) -- mime type that is parsed as string and then converted to a MimeType
            value -- the whole JS File object as a Json.Value so we can pass it to a library that reads the content with a native FileReader
