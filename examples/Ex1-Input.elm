import Html exposing (Html, div, input, button, h1, p, text, form)
import Html.Attributes exposing (type', id, style, multiple)
import Html.Events exposing (onClick, on, onSubmit)
import Task
import Html.App as Html

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

type Msg
    = Upload                                    -- independent button
    | FilesSelect Files                         -- Update model, but without file read
    | FilesSelectUpload Files                   -- Update model and read files
    | Submit String                             -- Submit button in form
    | FileDataSucceed String                    -- data returned when success
    | FileDataFail FileReader.Error             -- data returned when failed

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Upload ->
            ( model
            , Cmd.batch <|
                List.map (readTextFile << .blob) model.selected
            )

        FilesSelect fileInstances ->
            ( { model
                | selected = fileInstances
                , message = "Something selected"
               }
            , Cmd.none
            )
        FilesSelectUpload fileInstances ->
            ( { model | selected = fileInstances }
            , Cmd.batch <|
                List.map (readTextFile << .blob) fileInstances
            )
        Submit _ ->
            ( { model | message = Basics.toString model.selected }
            , Cmd.batch <|
                List.map (readTextFile << .blob) model.selected
            )

        FileDataSucceed str ->
            ( { model | contents = str :: model.contents }
            , Cmd.none )

        FileDataFail err ->
            ( { model | message = FileReader.toString err }
            , Cmd.none )

-- VIEW

view : Model -> Html Msg
view model =
    div [ containerStyles ]
        [ div []
            [ h1
                [] [ text "Single file select + Upload separate" ]
            , input
                [ type' "file"
                , onchange FilesSelect
                ] []
            , button
                [ onClick Upload ]
                [ text "Upload" ]
            ]
        , div []
            [ h1
                [] [ text "Multiple files with automatic upload" ]
            , input
                [ type' "file"
                , onchange FilesSelectUpload
                , multiple True
                ] []
            ]
        , form
            [ onSubmit (Submit "form0")
            ]
            [ h1
                [] [ text "Form with submit button" ]
            , input
                [ type' "file"
                , onchange FilesSelect
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

onchange action =
    on
        "change"
        (Json.object1 (\v -> action v) parseSelectedFiles)


containerStyles =
    style [ ( "padding", "20px") ]

-- TASKS

readTextFile : Json.Value -> Cmd Msg
readTextFile fileValue =
    readAsTextFile fileValue
        |> Task.perform FileDataFail FileDataSucceed

-- ----------------------------------
main =
    Html.program
        { init = (init, Cmd.none)
        , update = update
        , view = view
        , subscriptions = (always Sub.none)
        }
