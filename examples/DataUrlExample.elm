import Html exposing (Html, div, input, button, p, text, img)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onWithOptions)
import StartApp
import Effects exposing (Effects)
import Task
import Json.Decode exposing (..)
import Json.Encode

import Json.Decode as Json exposing (Value, andThen)

import FileReader exposing (..)
import MimeHelpers exposing (MimeType(..))
import DragDrop exposing (Action(Drop), dragDropEventHandlers, HoverState(..))
-- import Decoders exposing (..)


-- Model types

type alias Model =
  { dnDModel: DragDrop.HoverState
  , imageData: Maybe (FileContentDataUrl) -- the image data once it has been loaded
  , imageLoadError : Maybe (FileReader.Error) -- the Error in case loading failed
  }

init : Model
init =
  Model DragDrop.init Nothing Nothing

type Action =
  DnD DragDrop.Action
  | LoadImageCompleted (Result FileReader.Error FileContentDataUrl) -- the loading of the file contents is complete

-- UPDATE

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
      -- Case drop. Let the DnD library update it's model and emmit the loading effect
      DnD (Drop files) ->
        ( { model
          | dnDModel = DragDrop.update (Drop files) model.dnDModel
          }
          , loadFirstFile files
        )
      -- Other DnD cases. Let the DnD library update it's model.
      DnD a ->
        ( { model
          | dnDModel = DragDrop.update a model.dnDModel
          }
          , Effects.none
        )
      -- The loading effect has emmited the LoadImageCompleted action, check the result and update the model
      LoadImageCompleted result -> case result of
        Result.Err err ->
          ( { model
            | imageLoadError = Just err
            }
            , Effects.none
          )
        Result.Ok val ->
          ( { model
            | imageData = Just val
            }
            , Effects.none
          )

-- VIEW

dropAllowedForFile : NativeFile -> Bool
dropAllowedForFile file =
  case file.mimeType of
    Nothing ->
      False
    Just mimeType ->
      case mimeType of
        MimeHelpers.Image _ ->
            True
        _ ->
            False

view : Signal.Address Action -> Model -> Html
view address model =
    div
    (  countStyle model.dnDModel
    :: dragDropEventHandlers (Signal.forwardTo address DnD))
    [ renderImageOrPrompt model
    ]

renderImageOrPrompt : Model -> Html
renderImageOrPrompt model =
  case model.imageLoadError of
    Just err ->
      text (FileReader.toString err)
    Nothing ->
      case model.imageData of
      Nothing ->
        case model.dnDModel of
          Normal ->
            text "Drop stuff here"
          Hovering ->
            text "Gimmie!"
      Just result ->
        img [ property "src" result
          , style [("max-width", "100%")]]
          []

countStyle : DragDrop.HoverState -> Html.Attribute
countStyle dragState =
  style
    [ ("font-size", "20px")
    , ("font-family", "monospace")
    , ("display", "block")
    , ("width", "400px")
    , ("height", "200px")
    , ("text-align", "center")
    , ("background", case dragState of
                        DragDrop.Hovering ->
                            "#ffff99"
                        DragDrop.Normal ->
                            "#cccc99")
    ]

-- TASKS
loadFirstFile : List NativeFile -> Effects Action
loadFirstFile =
  loadFirstFileWithLoader loadData

loadData : FileRef -> Effects Action
loadData file =
    FileReader.readAsDataUrl file      -- will return a Task FileReader.Error Json.Value
        |> Task.toResult               -- gets turned into a Task Never (Result FileReader.Error Json.Value)
        |> Task.map LoadImageCompleted -- gets turned into the LoadImageCompleted Action with the Result as a payload
        |> Effects.task                -- return as Effects Action

-- small helper method to do nothing if 0 files were dropped, otherwise load the first file
loadFirstFileWithLoader : (FileRef -> Effects Action) -> List NativeFile -> Effects Action
loadFirstFileWithLoader loader files =
  let
    maybeHead = List.head <| List.map .blob
                              (List.filter dropAllowedForFile files)
  in
    case maybeHead of
      Nothing -> Effects.none
      Just file -> loader file

-- ----------------------------------
app =
    StartApp.start
        { init = (init, Effects.none)
        , update = update
        , view = view
        , inputs = []
        }

main =
    app.html

port tasks : Signal (Task.Task Effects.Never ())
port tasks =
    app.tasks
