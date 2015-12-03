module FileReader (Error(..), getTextFile, readAsArrayBuffer, readAsDataUrl) where
{-| Elm bindings to HTML5 Reader API.

# Read file as text string
@docs Error, getTextFile

-}

import Signal
import Task exposing (Task)

import Native.FileReader
import Json.Decode exposing (Value)

{-| FileReader can fail in one of four cases:

 - the Id specified in getTextFile does not match an input of type file in the document
 - the blob passed in was not valid
 - no file has been chosen
 - the contents of the file cannot be read. 
-}
type Error
    = IdNotFound
    | NoValidBlob
    | NoFileSpecified
    | ReadFail

{-| Takes the id of an `input` of `type="file"` and attempts
to read the text file associated with it by the user.

    getTextFile "upload"
-}
getTextFile : String -> Task Error String
getTextFile = Native.FileReader.getTextFile

{-| Takes a "File" or "Blob" JS object as a Json.Value 
and starts a task to read the contents as an ArrayBuffer.
The ArrayBuffer value returned in the Success case of the Task will
be represented as a Json.Value to Elm.

    getTextFile "upload"
-}
readAsArrayBuffer : Value -> Task Error Value
readAsArrayBuffer = Native.FileReader.readAsArrayBuffer

{-| Takes a "File" or "Blob" JS object as a Json.Value 
and starts a task to read the contents as an DataURL (so it can
be assigned to the src property of an img e.g.).
The DataURL value returned in the Success case of the Task will
be represented as a Json.Value to Elm.

    getTextFile "upload"
-}
readAsDataUrl : Value -> Task Error Value
readAsDataUrl = Native.FileReader.readAsDataUrl