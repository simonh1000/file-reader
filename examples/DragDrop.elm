{-
Based on original code from Daniel Bachler (danyx23)
-}

module DragDrop
  ( HoverState(..)
  , Action(Drop)
  , init
  , update
  , dragDropEventHandlers
  ) where

-- import Effects exposing (Effects)
-- import Html exposing (Html, Attribute, div, text)
import Html.Events exposing (onWithOptions)
import Json.Decode as Json

import FileReader exposing (parseDroppedFiles, NativeFile)

-- MODEL

type HoverState
    = Normal
    | Hovering

type alias Model = HoverState -- set to Hovering if the user is hovering with content over the drop zone

init : Model
init = Normal

-- UPDATE

type Action
    = DragEnter -- user enters the drop zone while dragging something
    | DragLeave -- user leaves drop zone
    | Drop (List NativeFile)

update : Action -> Model -> Model
update action model =
    case action of
        DragEnter ->
            Hovering
        DragLeave ->
            Normal
        Drop files ->
            Normal

-- View event handlers
dragDropEventHandlers : Signal.Address Action -> List Attribute
dragDropEventHandlers address =
    [ onDragEnter address DragEnter
    , onDragLeave address DragLeave
    , onDragOver address DragEnter
    , onDrop address
    ]

-- Individual handler functions
onDragFunctionIgnoreFiles : String -> Signal.Address a -> a -> Attribute
onDragFunctionIgnoreFiles nativeEventName address action =
    onWithOptions
        nativeEventName
        {stopPropagation = False, preventDefault = True}
        Json.value
        (\_ -> Signal.message address action)

onDragFunctionDecodeFiles : String -> (List NativeFile -> Action) -> Signal.Address Action -> Html.Attribute
onDragFunctionDecodeFiles nativeEventName actionCreator address =
    onWithOptions
        nativeEventName
        {stopPropagation = True, preventDefault = True}
        parseDroppedFiles
        (\vals -> Signal.message address (actionCreator vals))

onDragEnter : Signal.Address a -> a -> Attribute
onDragEnter =
  onDragFunctionIgnoreFiles "dragenter"

onDragOver : Signal.Address a -> a -> Attribute
onDragOver =
  onDragFunctionIgnoreFiles "dragover"

onDragLeave : Signal.Address a -> a -> Attribute
onDragLeave =
  onDragFunctionIgnoreFiles "dragleave"

onDrop : Signal.Address Action -> Html.Attribute
onDrop address =
  onDragFunctionDecodeFiles "drop" (\files -> Drop files) address
