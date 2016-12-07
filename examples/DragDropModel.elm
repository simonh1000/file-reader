{-
   Based on original code from Daniel Bachler (danyx23)
-}


module DragDropModel
    exposing
        ( HoverState(..)
        , Msg(Drop)
        , init
        , update
        , dragDropEventHandlers
        )

-- import Effects exposing (Effects)

import Html exposing (Attribute)
import Html.Events exposing (onWithOptions)
import Json.Decode as Json
import FileReader exposing (parseDroppedFiles, NativeFile)


-- MODEL


type HoverState
    = Normal
    | Hovering


type alias Model =
    HoverState



-- set to Hovering if the user is hovering with content over the drop zone


init : Model
init =
    Normal



-- UPDATE


type Msg
    = DragEnter
      -- user enters the drop zone while dragging something
    | DragLeave
      -- user leaves drop zone
    | Drop (List NativeFile)


update : Msg -> Model -> Model
update msg model =
    case msg of
        DragEnter ->
            Hovering

        DragLeave ->
            Normal

        Drop files ->
            Normal



-- View event handlers


dragDropEventHandlers : List (Attribute Msg)
dragDropEventHandlers =
    [ onDragEnter DragEnter
    , onDragLeave DragLeave
    , onDragOver DragEnter
    , onDrop
    ]



-- Individual handler functions


onDragFunctionIgnoreFiles : String -> a -> Attribute a
onDragFunctionIgnoreFiles nativeEventName action =
    onWithOptions
        nativeEventName
        { stopPropagation = False, preventDefault = True }
        (Json.map (\_ -> action) Json.value)


onDragFunctionDecodeFiles : String -> (List NativeFile -> Msg) -> Attribute Msg
onDragFunctionDecodeFiles nativeEventName actionCreator =
    onWithOptions
        nativeEventName
        { stopPropagation = True, preventDefault = True }
        (Json.map actionCreator parseDroppedFiles)


onDragEnter : a -> Attribute a
onDragEnter =
    onDragFunctionIgnoreFiles "dragenter"


onDragOver : a -> Attribute a
onDragOver =
    onDragFunctionIgnoreFiles "dragover"


onDragLeave : a -> Attribute a
onDragLeave =
    onDragFunctionIgnoreFiles "dragleave"


onDrop : Attribute Msg
onDrop =
    onDragFunctionDecodeFiles "drop" (\files -> Drop files)
