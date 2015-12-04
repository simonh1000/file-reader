import Html exposing (Html, div, input, button, p, text)
import Html.Attributes exposing (type', id)
import Html.Events exposing (onClick)
import StartApp
import Effects exposing (Effects)
import Task
import FileReader exposing (getTextFile, Error(..))

type alias Model = String

init : Model
init = ""

type Action
    = Upload
    | FileData String

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        Upload -> ( model, loadData )
        FileData str -> ( str, Effects.none )

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    div []
        -- [ input [ type' "file" ] []
        [ input [ type' "file", id "input" ] []
        , button [onClick address Upload] [ text <| "Upload" ]
        , p [ ] [ text <| "Contents: " ++ model ]
        ]

-- TASKS

loadData : Effects Action
loadData =
    getTextFile "input" `Task.onError` (\err -> Task.succeed (errorMapper err))
        |> Task.map FileData
        |> Effects.task

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
