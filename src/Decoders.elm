{-
Original code from Daniel Bachler (danyx23)
-}

module Decoders (..) where

import Json.Decode exposing (..)

-- Helper type for the File JS object that is used when the user drops files into the DropZone with DnD
type alias NativeFile =
  { name : String
  , blob : Value
  }


-- Json decoders for the somewhat weird drop eventdata structure
parseFilenameAt : Int -> Json.Decode.Decoder NativeFile
parseFilenameAt index =
    Json.Decode.at ["dataTransfer", "files"] <|
      Json.Decode.object2
        NativeFile
        ((toString index) := (Json.Decode.object1 identity ("name" := Json.Decode.string)))
        (toString index := Json.Decode.value)

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

-- returns file name
parseSelectFile : Decoder Value
parseSelectFile =
    at [ "target", "files" ] <|
        ((toString 0) := value)
-- parseSelectEvent : Decoder String
-- parseSelectEvent =
--     at [ "target", "files" ] <|
--         ((toString 0) := ("name" := string))
