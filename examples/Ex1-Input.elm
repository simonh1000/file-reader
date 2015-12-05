
import Html exposing (Html, div, input, button, h1, p, text, form)
import Html.Attributes exposing (type', id, style, multiple)
import Html.Events exposing (onClick, on, onSubmit)
import StartApp
import Effects exposing (Effects)
import Task

import Json.Decode as Json exposing (Value, andThen)

import FileReader exposing (getTextFile, readAsTextFile, Error(..))
import Decoders exposing (..)

type alias Files =
    List NativeFile
    -- List (String, NativeFile)

type alias Model =
    { result : String
    , selected : Files
    , contents : List String
    }

init : Model
init =
    { result = ""
    , selected = []
    , contents = []
    }

type Action
    = Upload String                             -- independent button
    | FilesSelect Files
    | FilesSelectUpload Files
    -- | Submit String
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
            , Effects.batch <|
                List.map (loadData' << .blob) fileInstances
            )
        -- Submit s ->
        --     ( { model | result = toString model.selected }
        --     , Effects.none
        --     )

        FileData (Result.Ok str) ->
            ( { model | contents = str :: model.contents }
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
                [] [ text "Single file select + Upload separate" ]
            , input
                [ type' "file"
                , id "input0"
                , onchange address FilesSelect
                ] []
            , button
                [ onClick address (Upload "input0") ]
                [ text "Upload" ]
            ]
        , div []
            [ h1
                [] [ text "Multi Select with automatic upload" ]
            , input
                [ type' "file"
                , onchange' address FilesSelectUpload
                , multiple True
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
            [ h1 [] [ text "Results" ]
            , p [] [ text <| "Selected files:" ++ List.foldl (++) "" (List.map .name model.selected) ]
            -- [ p [] [ text <| "Selected files:" ++ List.foldl (++) "" (List.map (.name << snd) model.selected) ]
            , p [] [ text <| "File contents: " ++ toString model.contents ]
            ]
        ]

onchange address action =
    on
        "change"
        parseSelectedFile                      -- Decode Value
        (\v -> Signal.message address (action [v]))

onchange' address action =
    on
        "change"
        parseSelectedFiles                      -- Decode Value
        -- (parseLength' `andThen` parseFilenames')
        (\v -> Signal.message address (action v))

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
