import Html exposing (Html, div, input, button, h1, p, text)
import Html.Attributes exposing (type', id, style)
import Html.Events exposing (onClick, on)
import StartApp
import Effects exposing (Effects)
import Task

import FileReader exposing (..)
import DragDrop exposing (Action(Drop), dragDropEventHandlers)
import MimeHelpers exposing (MimeType(Text))

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

type Action
    = DnD DragDrop.Action
    | FileData (Result FileReader.Error String)

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        DnD (Drop files) ->
            ( { model
              | dropZone = DragDrop.update (Drop files) model.dropZone
              , files = files
              }
            , Effects.batch <|
                List.map (readTextFile << .blob) files
            )
        DnD a ->                -- drag events
            ( { model | dropZone = DragDrop.update a model.dropZone }
            , Effects.none
            )

        FileData (Result.Ok str) ->
            ( { model | contents = str :: model.contents }
            , Effects.none
            )

        FileData (Result.Err err) ->
            ( { model | message = FileReader.toString err }
            , Effects.none
            )

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    div [ containerStyles ]
        [ h1 [] [ text "Drag 'n Drop" ]
        , renderDropZone address model.dropZone
        , div
            []
            [ text <| "Files: " ++ commaSeperate (List.map .name model.files)
            ]
        , div
            [] <|
            [ text <| "Content: " ++ commaSeperate model.contents ]
        , p [] [ text model.message ]
        ]

commaSeperate : List String -> String
commaSeperate lst =
    List.foldl (++) "" (List.intersperse ", " lst)

renderDropZone : Signal.Address Action -> DragDrop.HoverState -> Html
renderDropZone address hoverState =
  div
    (renderZoneAttributes address hoverState)
    []

renderZoneAttributes : Signal.Address Action -> DragDrop.HoverState -> List Html.Attribute
renderZoneAttributes address hoverState =
  (case hoverState of
        DragDrop.Normal ->
          dropZoneDefault
        DragDrop.Hovering ->
          dropZoneHover
  )
  ::
  dragDropEventHandlers (Signal.forwardTo address DnD)

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

readTextFile : FileRef -> Effects Action
readTextFile fileValue =
    readAsTextFile fileValue
        |> Task.toResult
        |> Task.map FileData
        |> Effects.task

-- will fail
sendFileToServer : FileContentArrayBuffer -> Task Http.Error ()
sendFileToServer buf =
    http.post "http://ww.google.com" buf
        |> Task.toResult
        |> Task.map ServerResponse
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
