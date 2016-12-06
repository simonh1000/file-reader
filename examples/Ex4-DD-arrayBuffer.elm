module Main exposing (..)

import Html exposing (Html, div, input, button, h1, p, text)
import Html.Attributes exposing (type_, id, style)
import Html.Events exposing (onClick, on)
import Json.Decode as Json exposing (Value, andThen)
import Http exposing (..)
import Task exposing (Task)
import List as L
import DragDrop exposing (..)
import FileReader exposing (..)


-- MODEL


type alias Model =
    { message : String
    , files :
        List NativeFile
        -- , files : List Json.Value
    , contents : List String
    }


init : Model
init =
    { message = "Waiting..."
    , files = []
    , contents = []
    }



-- UPDATE


type Msg
    = DragEnter
    | DragOver
    | DragLeave
      -- | Drop (List Json.Value)
    | Drop (List NativeFile)
    | Submit
    | FileData (Result FileReader.Error FileContentArrayBuffer)
    | PostResult (Result Http.Error Json.Value)


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        DragEnter ->
            model ! []

        DragOver ->
            model ! []

        DragLeave ->
            model ! []

        Drop files ->
            { model | files = files } ! []

        Submit ->
            case L.head model.files of
                Just file ->
                    model ! [ sendFileToServer file ]

                Nothing ->
                    model ! []

        FileData (Result.Ok buf) ->
            model ! []

        -- model ! [ sendFileToServer buf ]
        FileData (Result.Err err) ->
            { model | message = FileReader.prettyPrint err } ! []

        _ ->
            let
                _ =
                    Debug.log "PostResult" message
            in
                model ! []



-- VIEW


view : Model -> Html Msg
view model =
    div [ containerStyles ]
        [ h1 [] [ text "Drag 'n Drop" ]
        , renderDropZone model
        , button
            [ onClick Submit ]
            [ text "Submit" ]
        , div [] [ text <| "Files: " ++ commaSeperate (List.map .name model.files) ]
        , div [] [ text <| "Content: " ++ commaSeperate model.contents ]
        , p [] [ text model.message ]
        ]


commaSeperate : List String -> String
commaSeperate lst =
    List.foldl (++) "" (List.intersperse ", " lst)


renderDropZone : Model -> Html Msg
renderDropZone m =
    div
        (renderZoneAttributes m)
        [ text "drop here" ]


renderZoneAttributes : Model -> List (Html.Attribute Msg)
renderZoneAttributes _ =
    dropZoneDefault
        :: [ onDragEnter DragEnter
           , onDragOver DragEnter
           , onDragLeave DragLeave
           , onDrop Drop
           ]



-- case hoverState of
--     DragDrop.Normal ->
--         dropZoneDefault :: dragDropEventHandlers
--     DragDrop.Hovering ->
--         dropZoneHover :: dragDropEventHandlers
-- TASKS


readFile : FileRef -> Cmd Msg
readFile fileValue =
    readAsArrayBuffer fileValue
        |> Task.attempt FileData



-- sendFileToServer : FileContentArrayBuffer -> Cmd Msg


sendFileToServer buf =
    let
        body =
            Http.multipartBody
                [ stringPart "part1" "42"
                  -- , FileReader.blobPart "test" "testname.png" buf
                , FileReader.filePart "simtest" buf
                ]
                |> Debug.log "body"
    in
        Http.post "http://localhost:5000/upload" body Json.value
            |> Http.send PostResult



-- ----------------------------------------


containerStyles : Html.Attribute msg
containerStyles =
    style
        [ ( "padding", "20px" )
        ]


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



-- ----------------------------------


main =
    Html.program
        { init = ( init, Cmd.none )
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }
