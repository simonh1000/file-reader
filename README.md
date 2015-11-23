## Elm implementation of HTML5 Reader API

Takes the id of an `input` of `type="file"` and attempts to read the file associated with it by the user.

    getFileContents "upload"

Here is a full example of the code in use
```
type Action =
      | Upload
      | FileData String

update : Action -> Model -> (Model, Effects Action)
update action model =
    case action of
        Upload -> ( model, loadData )
        FileData str -> ( { model | data <- str }, Effects.none )
        -- note that str may be the error message

-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
    div []
        [ input [ type' "file", id "input" ] []
        , button [onClick address Upload] [ text <| "Upload" ]
        , p [] [ text <| "Contents: " ++ model.data ]
        ]

-- TASKS

loadData : Effects Action
loadData =
    getTextFile "input" `Task.onError` (\err -> Task.succeed (errorMapper err))
        |> Task.map FileData
        |> Effects.task

errorMapper : FileReader.Error -> String
errorMapper err =
    case err of
        FileReader.ReadFail -> "File reading error"
        FileReader.NoFileSpecified -> "No file specified"
```
