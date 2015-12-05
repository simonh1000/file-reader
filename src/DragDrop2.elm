{-
Based on original code from Daniel Bachler (danyx23)
-}

module DragDrop2 
  ( HoverState(..)
  , Action(Drop)
  , init
  , update
  , dragDropEventHandlers
  ) where

import Html exposing (Html, Attribute, div, text)
-- import Html.Attributes exposing (..)
import Html.Events exposing (onWithOptions)

import Json.Decode as Json exposing (andThen)
import Effects exposing (Effects)

import Decoders exposing (..)

-- MODEL

type HoverState
    = Normal
    | HoveringOk
    | HoveringRejected

type alias Model = HoverState -- set to Hovering if the user is hovering with content over the drop zone    

init : Model
init = Normal

-- UPDATE

type Action
    = DragEnter (List NativeFile) -- user enters the drop zone while dragging something
    | DragLeave -- user leaves drop zone
    | Drop (List NativeFile)

update : (List NativeFile -> Bool) -> Action -> Model -> Model
update dropAllowedFilter action model =
    case action of
        DragEnter files ->
            if (dropAllowedFilter files) then 
              HoveringOk
            else
              HoveringRejected
        DragLeave ->
            Normal            
        Drop files ->
            Normal

-- View event handlers
dragDropEventHandlers : Signal.Address Action -> List Attribute
dragDropEventHandlers address =
    [ onDragEnter address
    , onDragLeave address DragLeave
    , onDragOver address
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
        (parseLength `andThen` parseFilenames)
        (\vals -> Signal.message address (actionCreator vals))

onDragEnter : Signal.Address Action -> Attribute
onDragEnter address = 
  onDragFunctionDecodeFiles "dragenter" (\files -> DragEnter files) address 

onDragOver : Signal.Address Action -> Attribute
onDragOver address = 
  onDragFunctionDecodeFiles "dragover" (\files -> DragEnter files) address 

onDragLeave : Signal.Address a -> a -> Attribute
onDragLeave = 
  onDragFunctionIgnoreFiles "dragleave"

onDrop : Signal.Address Action -> Html.Attribute
onDrop address =
  onDragFunctionDecodeFiles "drop" (\files -> Drop files) address 


