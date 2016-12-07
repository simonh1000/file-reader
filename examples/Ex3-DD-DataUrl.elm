module Main exposing (..)

import Html exposing (Html, div, input, button, p, text, img)
import Html.Attributes exposing (..)
import Task
import FileReader exposing (..)
import MimeType exposing (MimeType(..))
import DragDropModel as DragDrop exposing (Msg(Drop), dragDropEventHandlers, HoverState(..))


type alias Model =
    { dnDModel : DragDrop.HoverState
    , imageData :
        Maybe FileContentDataUrl
        -- the image data once it has been loaded
    , imageLoadError :
        Maybe FileReader.Error
        -- the Error in case loading failed
    }


init : Model
init =
    Model DragDrop.init Nothing Nothing


type Msg
    = DnD DragDrop.Msg
    | FileData (Result Error FileContentDataUrl)



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- Case drop. Let the DnD library update it's model and emmit the loading effect
        DnD (Drop files) ->
            ( { model
                | dnDModel = DragDrop.update (Drop files) model.dnDModel
              }
            , loadFirstFile files
            )

        -- Other DnD cases. Let the DnD library update it's model.
        DnD a ->
            ( { model
                | dnDModel = DragDrop.update a model.dnDModel
              }
            , Cmd.none
            )

        FileData (Ok val) ->
            { model | imageData = Just val } ! []

        FileData (Err err) ->
            { model | imageLoadError = Just err } ! []



-- VIEW


dropAllowedForFile : NativeFile -> Bool
dropAllowedForFile file =
    case file.mimeType of
        Nothing ->
            False

        Just mimeType ->
            case mimeType of
                MimeType.Image _ ->
                    True

                _ ->
                    False


view : Model -> Html Msg
view model =
    Html.map DnD <|
        div
            (countStyle model.dnDModel
                :: dragDropEventHandlers
            )
            [ renderImageOrPrompt model
            ]


renderImageOrPrompt : Model -> Html a
renderImageOrPrompt model =
    case model.imageLoadError of
        Just err ->
            text (FileReader.prettyPrint err)

        Nothing ->
            case model.imageData of
                Nothing ->
                    case model.dnDModel of
                        Normal ->
                            text "Drop stuff here"

                        Hovering ->
                            text "Gimmie!"

                Just result ->
                    img
                        [ property "src" result
                        , style [ ( "max-width", "100%" ) ]
                        ]
                        []


countStyle : DragDrop.HoverState -> Html.Attribute a
countStyle dragState =
    style
        [ ( "font-size", "20px" )
        , ( "font-family", "monospace" )
        , ( "display", "block" )
        , ( "width", "400px" )
        , ( "height", "200px" )
        , ( "text-align", "center" )
        , ( "background"
          , case dragState of
                DragDrop.Hovering ->
                    "#ffff99"

                DragDrop.Normal ->
                    "#cccc99"
          )
        ]



-- TASKS


loadFirstFile : List NativeFile -> Cmd Msg
loadFirstFile =
    loadFirstFileWithLoader loadData


loadData : FileRef -> Cmd Msg
loadData file =
    FileReader.readAsDataUrl file
        |> Task.map Ok
        |> Task.onError (Task.succeed << Err)
        |> Task.perform FileData



-- small helper method to do nothing if 0 files were dropped, otherwise load the first file


loadFirstFileWithLoader : (FileRef -> Cmd Msg) -> List NativeFile -> Cmd Msg
loadFirstFileWithLoader loader files =
    let
        maybeHead =
            List.head <|
                List.map .blob
                    (List.filter dropAllowedForFile files)
    in
        case maybeHead of
            Nothing ->
                Cmd.none

            Just file ->
                loader file



-- ----------------------------------


main =
    Html.program
        { init = ( init, Cmd.none )
        , update = update
        , view = view
        , subscriptions = (always Sub.none)
        }
