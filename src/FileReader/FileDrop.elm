module FileReader.FileDrop exposing (draggableAttrs, dzAttrs, onDragEnd, onDragEnter, onDragLeave, onDragOver, onDragStart, onDrop, onPreventDefault, onSkipMsg, onStopAll, onStopPropagation)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (custom, on, preventDefaultOn, stopPropagationOn)
import Json.Decode as Jdec
import List as L


{-| attributes for something that is dragged
dragEnd is generally NoOp
-}
draggableAttrs : msg -> msg -> List (Attribute msg)
draggableAttrs dragStart dragEnd =
    [ draggable "true"
    , onDragStart dragStart
    , onDragEnd dragEnd
    ]


onDragStart : msg -> Attribute msg
onDragStart =
    onStopPropagation "dragstart"


onDragEnd : msg -> Attribute msg
onDragEnd msgCreator =
    onStopPropagation "dragend" msgCreator



--


dzAttrs : msg -> msg -> msg -> msg -> List (Attribute msg)
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


onDragOver : msg -> Attribute msg
onDragOver msg =
    -- onStopAll "dragover" msg
    onSkipMsg "dragover" msg


onDrop : msg -> Attribute msg
onDrop msgCreator =
    onPreventDefault "drop" msgCreator


onSkipMsg : String -> msg -> Attribute msg
onSkipMsg evt msg =
    onPreventDefault evt msg



--


onStopPropagation : String -> a -> Attribute a
onStopPropagation evt msgCreator =
    stopPropagationOn evt <| Jdec.succeed ( msgCreator, True )


onPreventDefault : String -> a -> Attribute a
onPreventDefault evt msgCreator =
    preventDefaultOn evt <| Jdec.succeed ( msgCreator, True )


onStopAll : String -> a -> Attribute a
onStopAll evt msgCreator =
    custom evt <|
        Jdec.succeed
            { message = msgCreator
            , stopPropagation = True
            , preventDefault = True
            }
