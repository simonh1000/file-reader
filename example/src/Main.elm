module Main exposing (main)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Json.Decode as Json exposing (Value)
import Task
import Http
import FileReader exposing (NativeFile)
import FileReader.FileDrop as DZ


type alias Model =
    { file : Maybe NativeFile
    , dragHovering : Int
    , content : String
    }


init : Model
init =
    { file = Nothing
    , dragHovering = 0
    , content = ""
    }


type Msg
    = OnDragEnter Int
    | OnDrop (List NativeFile)
    | StartUpload
    | OnFileContent (Result FileReader.Error String)
    | PostResult (Result Http.Error Value)
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        OnDragEnter inc ->
            ( { model | dragHovering = model.dragHovering + inc }, Cmd.none )

        OnDrop file ->
            case file of
                -- Only handling case of a single file
                [ f ] ->
                    ( { model | file = Just f, dragHovering = 0 }, getFileContents f )

                _ ->
                    ( { model | dragHovering = 0 }, Cmd.none )

        OnFileContent res ->
            case res of
                Ok content ->
                    ( { model | content = content }, Cmd.none )

                Err err ->
                    Debug.crash (toString err)

        StartUpload ->
            ( model, model.file |> Maybe.map sendFileToServer |> Maybe.withDefault Cmd.none )

        PostResult res ->
            case Debug.log "PostResult" res of
                _ ->
                    ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    let
        dzAttrs_ =
            DZ.dzAttrs (OnDragEnter 1) (OnDragEnter -1) NoOp OnDrop

        dzClass =
            if model.dragHovering > 0 then
                class "drop-zone active" :: dzAttrs_
            else
                class "drop-zone" :: dzAttrs_
    in
        div [ class "panel" ] <|
            [ h1 [] [ text "File Reader library example" ]
            , p [] [ text "Drag n Drop file below or use the file dialog to load file" ]
            , div dzClass
                [ input
                    [ type_ "file"
                    , FileReader.onFileChange OnDrop
                    , multiple False
                    ]
                    []
                ]
            , case model.file of
                Just nf ->
                    div []
                        [ span [] [ text nf.name ]
                        , button [ onClick StartUpload ] [ text "Upload" ]
                        , div [] [ small [] [ text model.content ] ]
                        ]

                Nothing ->
                    text ""
            ]



--


getFileContents : NativeFile -> Cmd Msg
getFileContents nf =
    FileReader.readAsTextFile nf.blob
        |> Task.attempt OnFileContent


sendFileToServer : NativeFile -> Cmd Msg
sendFileToServer nf =
    let
        body =
            Http.multipartBody
                [ Http.stringPart "part1" nf.name
                , FileReader.filePart "upload" nf
                ]
    in
        Http.post "http://localhost:5000/upload" body Json.value
            |> Http.send PostResult



--


main : Program Never Model Msg
main =
    Html.program
        { init = ( init, Cmd.none )
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }
