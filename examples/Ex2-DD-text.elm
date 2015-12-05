import Html exposing (Html, div, input, button, h1, p, text)
import Html.Attributes exposing (type', id, style)
import Html.Events exposing (onClick, on)
import StartApp
import Effects exposing (Effects)
import Task

import Json.Decode as Json exposing (Value, andThen)

import FileReader exposing (FileRef, readAsTextFile, Error(..))
import DragDrop exposing (Action(Drop))
import Decoders exposing (..)

-- MODEL

type alias Model =
    { message : String
    , dropZone : DragDrop.Model
    , files : List NativeFile
    , contents : List String
    }

init : Model
init =
    { message = "Waiting..."
    , dropZone = DragDrop.init dropZoneDefault dropZoneHover
    , files = []
    , contents = []
    }

-- UPDATE

type Action
    = DnD DragDrop.Action
    | FileData (Result FileReader.Error String)

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        DnD (Drop lst) ->
            ( { model
                | dropZone = fst <| DragDrop.update (Drop lst) model.dropZone   -- reset HoverState
                , files = lst
               }
            , Effects.batch <|
                List.map (loadData << .blob) lst
            )
        DnD a ->                -- drag events
            let
                (newModel, newEffects) =
                    DragDrop.update a model.dropZone
            in
                ( { model | dropZone = newModel }
                , Effects.map DnD newEffects
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
        [ h1 [] [ text "Drag 'n Drop" ]
        , DragDrop.view (Signal.forwardTo address DnD) model.dropZone
        , p [] [ text <| "files " ++
                (List.foldl (++) "" <| List.intersperse ", " <| List.map .name model.files) ]
        , div
            [] <|
            List.map text model.contents
        ]

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

loadData : FileRef -> Effects Action
loadData fileValue =
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
