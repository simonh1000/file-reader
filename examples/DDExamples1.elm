import Html exposing (Html, div, input, button, h1, p, text)
import Html.Attributes exposing (type', id, style)
import Html.Events exposing (onClick, on)
import StartApp
import Effects exposing (Effects)
import Task

import Json.Decode as Json exposing (Value, andThen)

import FileReader exposing (getTextFile, readAsTextFile, Error(..))
import DragDrop
import DragDropDecoder exposing (..)

type alias Model =
    { result : String
    , dropZone : DragDrop.Model
    }

init : Model
init =
    { result = ""
    , dropZone = DragDrop.init dropZoneDefault dropZoneHover
    }

type Action
    = Upload String
    -- | FileSet String
    | FileData (Result FileReader.Error String)
    | DnD DragDrop.Action
    | UploadSelected Value

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        Upload inputId ->
            ( model
            , loadData inputId
            )

        FileData (Result.Ok str) ->
            ( { model | result = toString str }
            , Effects.none )

        FileData (Result.Err err) ->
            ( { model | result = errorMapper err }
            , Effects.none )

        UploadSelected v ->
            ( { model | result = "loaded something" }
            , loadData' v
            )

        DnD a ->
            let
                (newModel, newEffects) =
                    DragDrop.update a model.dropZone
            in
                ( { model | dropZone = newModel }
                , Effects.map DnD newEffects
                )

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    div [ containerStyles ]
        [ div []
            [ h1 [] [ text "Select and Upload separate" ]
            , input
                [ type' "file"
                , id "input0"
                ] []
            , button
                [ onClick address (Upload "input0") ]
                [ text "Upload" ]
            , p [ ] [ text <| "File contents: " ++ model.result ]
            ]
        , div []
            [ h1 [] [ text "Select with automatic upload" ]
            , input
                [ type' "file"
                , id "input1"
                , onchange address
                ] []
            , p [ ] [ text <| "File contents: " ++ model.result ]
            ]
        -- , DragDrop.view (Signal.forwardTo address DnD) model.dropZone
        ]

onchange address =
    on
        "change"
        parseSelectEvent                      -- Decode Value
        (\v -> Signal.message address (UploadSelected v))

containerStyles =
    style
        [ ( "padding", "20px")
        ]
dropZoneDefault =
    style
        [ ( "height", "120px")
        , ( "border-radius", "10px")
        , ( "border", "3px dashed steelblue")
        ]
dropZoneHover =
    style
        [ ( "height", "120px")
        , ( "border-radius", "10px")
        , ( "border", "3px dashed red")
        ]

-- TASKS

loadData : String -> Effects Action
loadData inputId =
    getTextFile inputId
        |> Task.toResult
        |> Task.map FileData
        |> Effects.task
--
loadData' : Json.Value -> Effects Action
loadData' fileValue =
    readAsTextFile fileValue
        |> Task.toResult
        |> Task.map FileData
        |> Effects.task

errorMapper : FileReader.Error -> String
errorMapper err =
    case err of
        FileReader.ReadFail -> "File reading error"
        FileReader.NoFileSpecified -> "No file specified"
        FileReader.IdNotFound -> "Id Not Found"
        FileReader.NoValidBlob -> "Blob was not valid"

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
