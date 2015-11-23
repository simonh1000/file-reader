module FileReader (Error(..), getTextFile) where
{-| Elm bindings to HTML5 Reader API.

# Read file as text string
@docs Error, getTextFile

-}

import Signal
import Task exposing (Task)

import Native.FileReader

{-| FileReader can fail in one of three cases:

 - the Id specified in getTextFile does not match an input of type file in the document
 - no file has been chosen
 - the contents of the file cannot be read.
-}
type Error
    = IdNotFound
    | NoFileSpecified
    | ReadFail

{-| Takes the id of an `input` of `type="file"` and attempts
to read the text file associated with it by the user.

    getTextFile "upload"
-}
getTextFile : String -> Task Error String
getTextFile = Native.FileReader.getTextFile
