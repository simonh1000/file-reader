import Html exposing (Html, div, input, button, h1, p, text, form)
import Html.Attributes exposing (type', id, style, multiple)
import Html.Events exposing (onClick, on, onSubmit, onWithOptions)
import StartApp
import Effects exposing (Effects)
import Task

import Json.Decode as Json exposing (Value, andThen)

import FileReader exposing (..)

type alias Files =
    List NativeFile

type alias Model =
    { message : String
    , selected : Files
    , contents : List String
    }

init : Model
init =
    { message = "Waiting..."
    , selected = []
    , contents = []
    }

type Action
    = Upload                                    -- independent button
    | FilesSelect Files                         -- Update model, but without file read
    | FilesSelectUpload Files                   -- Update model and read files
    | Submit String                             -- Submit button in form
    | FileData (Result FileReader.Error String) -- data returned

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        Upload ->
            ( model
            , Effects.batch <|
                List.map (readTextFile << .blob) model.selected
            )

        FilesSelect fileInstances ->
            ( { model
                | selected = fileInstances
                , message = "Something selected"
               }
            , Effects.none
            )
        FilesSelectUpload fileInstances ->
            ( { model | selected = fileInstances }
            , Effects.batch <|
                List.map (readTextFile << .blob) fileInstances
            )
        Submit _ ->
            ( { model | message = Basics.toString model.selected }
            , Effects.batch <|
                List.map (readTextFile << .blob) model.selected
            )

        FileData (Result.Ok str) ->
            ( { model | contents = str :: model.contents }
            , Effects.none )

        FileData (Result.Err err) ->
            ( { model | message = FileReader.toString err }
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
                , onchange address FilesSelect
                ] []
            , button
                [ onClick address Upload ]
                [ text "Upload" ]
            ]
        , div []
            [ h1
                [] [ text "Multiple files with automatic upload" ]
            , input
                [ type' "file"
                , onchange address FilesSelectUpload
                , multiple True
                ] []
            ]
        , form
            [ onsubmit address (Submit "form0")
            ]
            [ h1
                [] [ text "Form with submit button" ]
            , input
                [ type' "file"
                , onchange address FilesSelect
                , multiple True
                ] []
            , button
                [ type' "submit" ]
                [ text "Submit" ]
            ]
        , div []
            [ h1 []
                [ text "Results" ]
            , p []
                [ text <|
                    "Files: " ++ commaSeperate (List.map .name model.selected)
                ]
            , p []
                [ text <|
                    "Contents: " ++ commaSeperate model.contents
                ]
            , p []
                [ text model.message ]
            ]
        ]

commaSeperate : List String -> String
commaSeperate lst =
    List.foldl (++) "" (List.intersperse ", " lst)

onchange address action =
    on
        "change"
        parseSelectedFiles                      -- Decode (List NativeFile)
        (\v -> Signal.message address (action v))

onsubmit address action =  -- onSubmit but with preventDefault
    onWithOptions
        "submit"
        {stopPropagation = False, preventDefault = True}
        Json.value
        (\_ -> Signal.message address action)

containerStyles =
    style [ ( "padding", "20px") ]

-- TASKS

readTextFile : Json.Value -> Effects Action
readTextFile fileValue =
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
