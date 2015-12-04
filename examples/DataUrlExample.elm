import Html exposing (Html, div, input, button, p, text, img)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onWithOptions)
import StartApp
import Effects exposing (Effects)
import Task
import FileReader exposing (readAsDataUrl, Error(..))
import Json.Decode exposing (..)
import Json.Encode

-- Model types
type alias ImageData = Value

type HoverState
  = Normal
  | Hovering

type alias Model =
  { hoverState : HoverState -- set to Hovering if the user is hovering with content over the drop zone
  , imageData: Maybe (ImageData) -- the image data once it has been loaded
  , imageLoadError : Maybe (FileReader.Error) -- the Error in case loading failed
  }

init : Model
init = Model Normal Nothing Nothing

-- Helper type for the File JS object that is used when the user drops files into the DropZone with DnD
type alias NativeFile =
  { name : String
  , blob : Value
  }

type Action = DragEnter -- user enters the drop zone while dragging something
  | DragLeave -- user leaves drop zone
  | Drop (List NativeFile) -- drop of a number of files
  | LoadImageCompleted (Result FileReader.Error Json.Decode.Value) -- the loading of the file contents is complete

-- DnD handlers
onDragFunction : String -> Signal.Address a -> a -> Html.Attribute
onDragFunction nativeEventName address payload =
  onWithOptions
    nativeEventName
    {stopPropagation = False, preventDefault = True}
    Json.Decode.value
    (\_ -> Signal.message address payload)

onDragEnter : Signal.Address a -> a -> Html.Attribute
onDragEnter = onDragFunction "dragenter"

onDragOver : Signal.Address a -> a -> Html.Attribute
onDragOver = onDragFunction "dragover"

onDragLeave : Signal.Address a -> a -> Html.Attribute
onDragLeave = onDragFunction "dragleave"

-- Json decoders for the somewhat weird drop eventdata structure
-- Int ????
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
parseLength = Json.Decode.at ["dataTransfer", "files"] <| oneOf
  [ Json.Decode.object1 identity ("length" := Json.Decode.int)
  , null 0
  ]

onDrop : Signal.Address Action -> Html.Attribute
onDrop address = onWithOptions "drop" {stopPropagation = True, preventDefault = True} (parseLength `andThen` parseFilenames) (\vals -> Signal.message address (Drop vals))

-- UPDATE

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
      DragEnter -> ({model | hoverState = Hovering}, Effects.none)
      DragLeave -> ({model | hoverState = Normal}, Effects.none)
      Drop files -> ( {model | hoverState = Normal}, loadFirstFile files loadData)
      LoadImageCompleted result -> case result of
        Result.Err err -> ( {model | imageLoadError = Just err}, Effects.none )
        Result.Ok val -> ( {model | imageData = Just val}, Effects.none )

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    div
    [
      countStyle model.hoverState
      , onDragEnter address DragEnter
      , onDragLeave address DragLeave
      , onDragOver address DragEnter
      , onDrop address
    ]
    [ renderImageOrPrompt model
    ]

renderImageOrPrompt : Model -> Html
renderImageOrPrompt model =
  case model.imageLoadError of
    Just err -> text (errorMapper err)
    Nothing -> case model.imageData of
      Nothing -> text "Drop stuff here"
      Just result -> img [ property "src" result
        , property "max-width" (Json.Encode.string "100%")]
        []

countStyle : HoverState -> Html.Attribute
countStyle dragState =
  style
    [ ("font-size", "20px")
    , ("font-family", "monospace")
    , ("display", "block")
    , ("width", "400px")
    , ("height", "200px")
    , ("text-align", "center")
    , ("background", if (dragState == Hovering) then "#ffff99" else "#cccc99")
    ]

-- TASKS
loadData : Json.Decode.Value -> Effects Action
loadData file =
    readAsDataUrl file   -- will return a Task FileReader.Error Json.Value
        |> Task.toResult -- gets turned into a Task Never (Result FileReader.Error Json.Value)
        |> Task.map LoadImageCompleted -- (turned into the LoadImageCompleted Action with the Result as a payload)
        |> Effects.task -- return as Effects Action

-- small helper method to do nothing if 0 files were dropped, otherwise load the first file
loadFirstFile : List NativeFile -> (Json.Decode.Value -> Effects Action) -> Effects Action
loadFirstFile files loader =
  let
    maybeHead = List.head <| List.map .blob files
  in
    case maybeHead of
      Nothing -> Effects.none
      Just file -> loader file

errorMapper : FileReader.Error -> String
errorMapper err =
    case err of
        FileReader.ReadFail -> "File reading error"
        FileReader.NoFileSpecified -> "No file specified"
        FileReader.IdNotFound -> "Id Not Found"
        FileReader.NoValidBlob -> "Given Blob was not valid"

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
