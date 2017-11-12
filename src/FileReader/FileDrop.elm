module FileReader.FileDrop exposing (..)

import Html exposing (Attribute)
import Html.Events exposing (onWithOptions, Options)
import Json.Decode as Json
import FileReader exposing (parseDroppedFiles, NativeFile)


dzAttrs : msg -> msg -> msg -> (List NativeFile -> msg) -> List (Attribute msg)
dzAttrs dragEnter dragLeave dragOverMsg dropMsg =
    [ onDragEnter dragEnter
    , onDragLeave dragLeave
    , onDragOver dragOverMsg -- Needed for drop to work - should generally be passed NoOp
    , onDropFiles dropMsg
    ]



--


onDragEnter : msg -> Attribute msg
onDragEnter msgCreator =
    onPreventDefault "dragenter" msgCreator


onDragLeave : msg -> Attribute msg
onDragLeave msgCreator =
    onPreventDefault "dragleave" msgCreator


onDragOver : msg -> Attribute msg
onDragOver =
    onPreventDefault "dragover"



-- onDrop : msg -> Attribute msg
-- onDrop msgCreator =
--     onPreventDefault "drop" msgCreator


onDropFiles : (List NativeFile -> msg) -> Attribute msg
onDropFiles msgCreator =
    onWithOptions "drop" stopProp <|
        Json.map msgCreator parseDroppedFiles



-- Helpers


stopProp : Options
stopProp =
    { stopPropagation = False, preventDefault = True }


preventDef : Options
preventDef =
    { stopPropagation = False, preventDefault = True }


onStopPropagation : String -> a -> Attribute a
onStopPropagation evt msgCreator =
    onWithOptions evt stopProp <|
        Json.succeed msgCreator


onPreventDefault : String -> a -> Attribute a
onPreventDefault evt msgCreator =
    onWithOptions evt preventDef <|
        Json.succeed msgCreator
