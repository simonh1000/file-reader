module FileReader.FileDrop exposing (dzAttrs, onDragEnter, onDragLeave, onDragOver, onDrop, onPreventDefault, onStopAll, onStopPropagation)

import Dict exposing (Dict)
import FileReader exposing (NativeFile)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (custom, on, preventDefaultOn, stopPropagationOn)
import Json.Decode as Decode
import List as L


{-| dragOverMsg should be a NoOp
-}
dzAttrs : msg -> msg -> msg -> (List NativeFile -> msg) -> List (Attribute msg)
dzAttrs dragEnter dragLeave dragOverMsg dropMsg =
    [ onDragEnter dragEnter
    , onDragLeave dragLeave
    , onDragOver dragOverMsg
    , onDrop dropMsg
    ]


onDragEnter : msg -> Attribute msg
onDragEnter msgCreator =
    onStopAll "dragenter" msgCreator


onDragLeave : msg -> Attribute msg
onDragLeave msgCreator =
    onStopAll "dragleave" msgCreator


{-| Not used as such, but we need to handle it for some reasom
-}
onDragOver : msg -> Attribute msg
onDragOver msg =
    onPreventDefault "dragover" msg


onDrop : (List NativeFile -> msg) -> Attribute msg
onDrop msgCreator =
    FileReader.parseDroppedFiles
        |> Decode.map (\nfs -> ( msgCreator nfs, True ))
        |> preventDefaultOn "drop"



--


onStopPropagation : String -> a -> Attribute a
onStopPropagation evt msgCreator =
    stopPropagationOn evt <| Decode.succeed ( msgCreator, True )


onPreventDefault : String -> a -> Attribute a
onPreventDefault evt msgCreator =
    preventDefaultOn evt <| Decode.succeed ( msgCreator, True )


onStopAll : String -> a -> Attribute a
onStopAll evt msgCreator =
    custom evt <|
        Decode.succeed
            { message = msgCreator
            , stopPropagation = True
            , preventDefault = True
            }
