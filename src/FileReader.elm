module FileReader
    ( FileRef
    , FileContentArrayBuffer
    , FileContentDataUrl
    , Error(..)
    , readAsTextFile
    , readAsArrayBuffer
    , readAsDataUrl
    , toString
    ) where

{-| Elm bindings to HTML5 Reader API.

# Read file as text string
@docs Error, readAsTextFile, readAsArrayBuffer, readAsDataUrl

-}

import Signal
import Task exposing (Task)

import Native.FileReader
import Json.Decode exposing (Value)

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
        -- IdNotFound -> "Id Not Found"
        -- NoFileSpecified -> "No file specified"
