port module Main exposing (main)

import Browser
import FileReader exposing (NativeFile)
import FileReader.FileDrop as DZ
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Task


type alias Model =
    { file : Maybe NativeFile
    , dragHovering : Int
    , content : String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( blankModel, Cmd.none )


blankModel =
    { file = Nothing
    , dragHovering = 0
    , content = ""
    }


type Msg
    = OnFileChange NativeFile
    | OnPortMsg PortMsg
      -- Drag n Drop
    | OnDragEnter Int
    | OnDrop (List NativeFile)
      -- Upload
    | StartUpload -- "upload" button
    | OnPostResult (Result Http.Error Value)
    | NoOp -- used for "dragover" event


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case Debug.log "update" message of
        OnFileChange nativeFile ->
            ( { model | file = Just nativeFile }, getFileContents nativeFile )

        OnPortMsg pMsg ->
            case decodePortMsg pMsg of
                TextFile content ->
                    ( { model | content = content }, Cmd.none )

                Error err ->
                    ( { model | content = err }, Cmd.none )

                _ ->
                    ( { model | content = "err" }, Cmd.none )

        OnDragEnter inc ->
            ( { model | dragHovering = model.dragHovering + inc }, Cmd.none )

        OnDrop nfs ->
            case nfs of
                -- Only handling case of a single file
                [ nf ] ->
                    ( { model | file = Just nf, dragHovering = 0 }, getFileContents nf )

                _ ->
                    ( { model | dragHovering = 0, content = "Only drop one file" }, Cmd.none )

        StartUpload ->
            ( model
            , model.file
                |> Maybe.map (\nf -> sendFileToServer { nf | blob = Encode.string model.content })
                |> Maybe.withDefault Cmd.none
            )

        OnPostResult res ->
            case Debug.log "OnPostResult" res of
                _ ->
                    ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


getFileContents : NativeFile -> Cmd msg
getFileContents nf =
    toJs
        { tag = "readAsText"
        , payload =
            Encode.object
                [ ( "tag", Encode.string "TextFile" )
                , ( "blob", nf.blob )
                ]
        }


sendFileToServer : NativeFile -> Cmd Msg
sendFileToServer nf =
    let
        body =
            Http.multipartBody
                [ Http.stringPart "part1" nf.name

                -- Next line needs to be able to take blob, but it can't!
                , Http.stringPart "upload" nf
                ]
    in
    Http.post "http://localhost:5000/upload" body Decode.value
        |> Http.send OnPostResult



-- VIEW


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
                , FileReader.onFileChange OnFileChange
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
{- ---------------------
   -- Ports

   {tag: "readAsText", payload: {returnTag: "TextFile", blob: blob} }
   {returnTag: "TextFile", payload: {content: <contents of file>}}
   {returnTag: "TextFile", payload: {error: "some message"}}
   -- --------------------
-}


type alias PortMsg =
    { tag : String
    , payload : Value
    }


port toJs : PortMsg -> Cmd msg


port fromJs : (PortMsg -> msg) -> Sub msg


type Payload
    = TextFile String
    | BinaryFile
    | DataURL
    | Error String


decodePortMsg : PortMsg -> Payload
decodePortMsg portMsg =
    case portMsg.tag of
        "TextFile" ->
            Decode.decodeValue decodeTextFile portMsg.payload
                |> Result.withDefault (Error "Decode error")

        _ ->
            Error "unrecognised tag"


decodeTextFile : Decoder Payload
decodeTextFile =
    Decode.oneOf
        [ Decode.field "data" Decode.string |> Decode.map TextFile
        , decodeError
        ]


decodeError : Decoder Payload
decodeError =
    Decode.field "error" Decode.string |> Decode.map Error



--


main =
    Browser.document
        { init = init
        , update = update
        , view = \m -> { body = [ view m ], title = "example" }
        , subscriptions = \_ -> fromJs OnPortMsg
        }
