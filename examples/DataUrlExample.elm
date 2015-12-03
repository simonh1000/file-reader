import Html exposing (Html, div, input, button, p, text, img)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onWithOptions)
import StartApp
import Effects exposing (Effects)
import Task
import FileReader exposing (readAsDataUrl, Error(..))
import Json.Decode as Json exposing (..)

type alias ImageData = Value

type HoverState = 
  Normal
  | Hovering

type alias Model = 
  { hoverState : HoverState
  , imageData: Maybe (ImageData)
  , imageLoadError : Maybe (FileReader.Error)
  } 

init : Model
init = Model Normal Nothing Nothing
 
type alias NativeFile =
  { name : String
  , blob : Value    
  }

type Action = DragEnter
  | DragLeave
  | Drop (List NativeFile)
  | LoadImageCompleted (Maybe Json.Value)
--  | LoadImageFailed FileReader.Error


onDragFunction : String -> Signal.Address a -> a -> Html.Attribute
onDragFunction nativeEventName address payload =
  onWithOptions nativeEventName {stopPropagation = False, preventDefault = True} Json.value (\_ -> Signal.message address payload)

onDragEnter : Signal.Address a -> a -> Html.Attribute
onDragEnter = onDragFunction "dragenter"

onDragOver : Signal.Address a -> a -> Html.Attribute
onDragOver = onDragFunction "dragover"

onDragLeave : Signal.Address a -> a -> Html.Attribute
onDragLeave = onDragFunction "dragleave"

parseFilenameAt : Int -> Json.Decoder NativeFile
parseFilenameAt index = Json.at ["dataTransfer", "files"] <|
  Json.object2 NativeFile ((toString index) := (Json.object1 identity ("name" := Json.string))) (toString index := Json.value)

parseFilenames : Int -> Json.Decoder (List NativeFile)
parseFilenames count =
 case count of
    0 ->
      succeed []
    _ ->
      Json.object2 (::) (parseFilenameAt (count - 1)) (parseFilenames (count - 1))
  
parseLength : Json.Decoder Int
parseLength = Json.at ["dataTransfer", "files"] <| oneOf 
  [ Json.object1 identity ("length" := Json.int)
  , null 0 
  ]

onDrop : Signal.Address Action -> Html.Attribute
onDrop address = onWithOptions "drop" {stopPropagation = True, preventDefault = True} (parseLength `andThen` parseFilenames) (\vals -> Signal.message address (Drop vals))

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
      DragEnter -> ({model | hoverState = Hovering}, Effects.none)
      DragLeave -> ({model | hoverState = Normal}, Effects.none)
      Drop files -> ( {model | hoverState = Normal}, loadFirstFile files loadData)
      LoadImageCompleted val -> ( {model | imageData = val}, Effects.none )

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
    [ text "Drop stuff here"
    ]

renderImageOrPrompt : Model -> Html
renderImageOrPrompt model = 
  case model.imageLoadError of
    Just err -> text (errorMapper err)
    Nothing -> case model.imageData of
      Nothing -> text "Drop stuff here"
      Just result -> img [property "src" result] []

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

loadData : Json.Value -> Effects Action
loadData file =
    readAsDataUrl file
        |> Task.toMaybe     
        |> Task.map LoadImageCompleted
        |> Effects.task

loadFirstFile : List NativeFile -> (Json.Value -> Effects Action) -> Effects Action
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
        FileReader.NoValidBlob -> "Give Blob was not valid"

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