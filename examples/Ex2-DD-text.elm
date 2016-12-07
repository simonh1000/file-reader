module Main exposing (..)

import Html exposing (Html, div, input, button, h1, p, text)
import Html.Attributes exposing (type_, id, style)
import Task
import Json.Decode as Json
import FileReader exposing (FileRef, NativeFile, readAsTextFile, Error(..))
import DragDropModel as DragDrop exposing (Msg(Drop), dragDropEventHandlers)


-- MODEL


type alias Model =
    { message : String
    , dropZone : DragDrop.HoverState
    , files : List NativeFile
    , contents : List String
    }


init : Model
init =
    { message = "Waiting..."
    , dropZone = DragDrop.init
    , files = []
    , contents = []
    }



-- UPDATE


type Msg
    = DnD DragDrop.Msg
    | FileData (Result Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DnD (Drop files) ->
            ( { model
                | dropZone =
                    DragDrop.update (Drop files) model.dropZone
                    -- reset HoverState
                , files = files
              }
            , Cmd.batch <|
                List.map (readTextFile << .blob) files
            )

        DnD a ->
            -- drag events
            ( { model | dropZone = DragDrop.update a model.dropZone }
            , Cmd.none
            )

        FileData (Ok str) ->
            { model | contents = str :: model.contents } ! []

        FileData (Err err) ->
            { model | message = FileReader.prettyPrint err } ! []



-- VIEW


view : Model -> Html Msg
view model =
    div [ containerStyles ]
        [ h1 [] [ text "Drag 'n Drop a text file" ]
        , renderDropZone model.dropZone
        , div
            []
            [ text <| "Files: " ++ commaSeparate (List.map .name model.files)
            ]
        , div []
            [ text <| "Content: " ++ commaSeparate model.contents ]
        , p [] [ text model.message ]
        ]


commaSeparate : List String -> String
commaSeparate lst =
    List.foldl (++) "" (List.intersperse ", " lst)


renderDropZone : DragDrop.HoverState -> Html Msg
renderDropZone hoverState =
    Html.map DnD <|
        div
            (renderZoneAttributes hoverState)
            []


renderZoneAttributes : DragDrop.HoverState -> List (Html.Attribute DragDrop.Msg)
renderZoneAttributes hoverState =
    (case hoverState of
        DragDrop.Normal ->
            dropZoneDefault

        DragDrop.Hovering ->
            dropZoneHover
    )
        :: dragDropEventHandlers


containerStyles =
    style [ ( "padding", "20px" ) ]


dropZoneDefault =
    style
        [ ( "height", "120px" )
        , ( "border-radius", "10px" )
        , ( "border", "3px dashed steelblue" )
        ]


dropZoneHover =
    style
        [ ( "height", "120px" )
        , ( "border-radius", "10px" )
        , ( "border", "3px dashed red" )
        ]



-- TASKS


readTextFile : FileRef -> Cmd Msg
readTextFile fileValue =
    readAsTextFile fileValue
        |> Task.map Ok
        |> Task.onError (Task.succeed << Err)
        |> Task.perform FileData



-- ----------------------------------


main =
    Html.program
        { init = ( init, Cmd.none )
        , update = update
        , view = view
        , subscriptions = (always Sub.none)
        }
