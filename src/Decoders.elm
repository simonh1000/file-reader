{-
Based on original code from Daniel Bachler (danyx23)
-}

module Decoders (..) where

import FileReader exposing (FileRef)
import Json.Decode exposing (..)
import MimeHelpers

-- Helper type for the File JS object that is used when the user drops files into the DropZone with DnD
type alias NativeFile =
  { name : String
  , size : Int
  , mimeType : Maybe MimeHelpers.MimeType
  , blob : Value
  }


-- Json decoders for the somewhat weird drop eventdata structure. the .dataTransfer.files property is a JS FileList object which is not an array so cannot
-- be parsed with Json.Decode.array, but has to be accessed in the form .dataTransfer.files[index]. This hopefully explains the strange (toString index)
-- way to get a file at an index
parseFilenameAt : Int -> Json.Decode.Decoder NativeFile
parseFilenameAt index =
  Json.Decode.at ["dataTransfer", "files"] <|
    (toString index) := nativeFile

parseFilenames : Int -> Json.Decode.Decoder (List NativeFile)
parseFilenames count =
    case count of
        0 ->
            succeed []
        _ ->
            Json.Decode.object2 (::) (parseFilenameAt (count - 1)) (parseFilenames (count - 1))

parseLength : Json.Decode.Decoder Int
parseLength =
    Json.Decode.at ["dataTransfer", "files"] <|
        oneOf
            [ Json.Decode.object1 identity ("length" := Json.Decode.int)
            , null 0
            ]

nativeFile : Decoder NativeFile
nativeFile =
    Json.Decode.object4
        NativeFile
            (Json.Decode.object1 identity ("name" := Json.Decode.string)) -- name
            (Json.Decode.object1 identity ("size" := Json.Decode.int)) -- size
            (Json.Decode.object1 MimeHelpers.parseMimeType ("type" := Json.Decode.string)) -- mime type that is parsed as string and then converted to a MimeType
            Json.Decode.value -- the whole JS File object as a Json.Value so we can pass it to a library that reads the content with a native FileReader

-- returns first file
parseSelectFile : Decoder NativeFile
parseSelectFile =
    at
        [ "target", "files" ]
        ((toString 0) := nativeFile)
        -- ((toString 0) := value)

-- NOT WORKING!!
parseDroppedFiles : Json.Decode.Decoder (List NativeFile)
parseDroppedFiles =
    Json.Decode.at ["dataTransfer", "files"]
        (list nativeFile)

parseSelectFiles : Decoder (List NativeFile)
parseSelectFiles =
    at [ "target", "files" ]
        (list nativeFile)
