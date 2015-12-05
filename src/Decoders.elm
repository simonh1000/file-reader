{-
Based on original code from Daniel Bachler (danyx23)
-}

module Decoders (..) where

import FileReader exposing (FileRef)
import Json.Decode as Json exposing (..)
import MimeHelpers

-- Helper type for the File JS object that is used when the user drops files into the DropZone with DnD
type alias NativeFile =
  { name : String
  , size : Int
  , mimeType : Maybe MimeHelpers.MimeType
  , blob : Value
  }


-- Json decoders for the somewhat weird drop eventdata structure. the .dataTransfer.files property is a JS FileList object which is not an array so cannot
-- be parsed with array, but has to be accessed in the form .dataTransfer.files[index]. This hopefully explains the strange (toString index)
-- way to get a file at an index
parseFilenameAt : Int -> Decoder NativeFile
parseFilenameAt index =
    at ["dataTransfer"] (fileAt index)
  -- at ["dataTransfer", "files"] <|
  --   (toString index) := nativeFile

parseLength : Decoder Int
parseLength =
    at ["dataTransfer" ] filesLength

parseFilenames : Int -> Decoder (List NativeFile)
parseFilenames count =
    case count of
        0 ->
            succeed []
        _ ->
            object2 (::) (parseFilenameAt (count - 1)) (parseFilenames (count - 1))

-- this is a better name I think
parseFiles = parseFilenames

-- Helpers
filesLength : Decoder Int
filesLength =
    at ["files"] <|
        oneOf
            [ object1 identity ("length" := int)
            , null 0
            ]

fileAt : Int -> Decoder NativeFile
fileAt index =
  at ["files"] <|
    (toString index) := nativeFile

nativeFile : Decoder NativeFile
nativeFile =
    object4
        NativeFile
            (object1 identity ("name" := string)) -- name
            (object1 identity ("size" := int)) -- size
            (object1 MimeHelpers.parseMimeType ("type" := string)) -- mime type that is parsed as string and then converted to a MimeType
            value -- the whole JS File object as a Json.Value so we can pass it to a library that reads the content with a native FileReader

pp : Int -> Decoder (List NativeFile)
pp count =
    List.foldl (\e acc -> Json.object2 (::) (fileAt e) acc) (succeed []) [0..(count-1)]

-- returns first file
parseSelectedFile : Decoder NativeFile
parseSelectedFile =
    -- at [ "target", "files" ] ("0" := nativeFile)
    at [ "target" ] (fileAt 0)

parseSelectedFiles : Decoder (List NativeFile)
parseSelectedFiles =
    at
        [ "target" ]
        (filesLength `andThen` pp)
        -- <| at ["files"]
        --     <| object2
        --         (\a b -> [a,b])
        --         ("0" := nativeFile)
        --         ("1" := nativeFile)
        -- <| Json.map (List.map snd) (keyValuePairs nativeFile)

parseDroppedFiles : Decoder (List NativeFile)
parseDroppedFiles =
    at
        [ "dataTransfer" ]
        <| filesLength `andThen` pp
--     at ["dataTransfer"] parseFiles
    -- at ["dataTransfer", "files"] <|
    --     map (List.map snd) <| keyValuePairs nativeFile
