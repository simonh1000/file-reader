
import Html exposing (Html, div, input, button, h1, p, text, form)
import Html.Attributes exposing (type', id, style, multiple)
import Html.Events exposing (onClick, on, onSubmit)
import StartApp
import Effects exposing (Effects)
import Task

import Json.Decode as Json exposing (Value, andThen)

import FileReader exposing (getTextFile, readAsTextFile, Error(..))
import Decoders exposing (..)

type alias Model =
    { result : String
    , selected : List NativeFile
    }

init : Model
init =
    { result = ""
    , selected = []
    }

type Action
    = Upload String                             -- independent button
    | FilesSelect (List NativeFile)
    | FilesSelectUpload (List NativeFile)
    | Submit String
    | FileData (Result FileReader.Error String) --
    -- | UploadSelected NativeFile

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        Upload inputId ->
            ( model
            , loadData inputId
            )

        FilesSelect fileInstances ->
            ( { model
                | selected = fileInstances
                , result = "Something selected"
               }
            , Effects.none
            )
        FilesSelectUpload fileInstances ->
            ( { model | selected = fileInstances }
            , case List.head fileInstances of
                Just file -> loadData' file.blob
                Nothing -> Effects.none
            )
        Submit s ->
            ( { model | result = toString model.selected }
            , Effects.none
            )

        FileData (Result.Ok str) ->
            ( { model | result = toString str }
            , Effects.none )

        FileData (Result.Err err) ->
            ( { model | result = FileReader.toString err }
            , Effects.none )


-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    div [ containerStyles ]
        [ div []
            [ h1
                [] [ text "Select and Upload separate" ]
            , input
                [ type' "file"
                , id "input0"
                , onchange address FilesSelect
                , multiple True
                ] []
            , button
                [ onClick address (Upload "input0") ]
                [ text "Upload" ]
            ]
        , div []
            [ h1
                [] [ text "Select with automatic upload" ]
            , input
                [ type' "file"
                , id "input1"
                , onchange address FilesSelectUpload
                ] []
            ]
        -- , form
        --     [ id "form0"
        --     , onSubmit address (Submit "form0")
        --     ]
        --     [ h1
        --         [] [ text "Form, multi and button" ]
        --     , input
        --         [ type' "file"
        --         , multiple True
        --         , onchange' address SelectedFiles
        --         ] []
        --     , button
        --         [ type' "submit"
        --         ] [ text "Submit" ]
        --     ]
        , div []
            -- [ p [] [ text <| "Selected files: " ++ toString model.selected ]
            [ p [] [ text <| "Selected files:" ++ List.foldl (++) "" (List.map .name model.selected) ]
            , p [] [ text <| "File contents: " ++ model.result ]
            ]
        ]

onchange address action =
    on
        "change"
        parseSelectFile                      -- Decode Value
        (\v -> Signal.message address (action [v]))

-- onchange' address action =
--     on
--         "change"
--         parseSelectFiles                      -- Decode Value
--         (\v -> Signal.message address (action v))

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
