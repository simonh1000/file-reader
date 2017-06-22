module FileReader
    exposing
        ( FileRef
        , FileContentArrayBuffer
        , FileContentDataUrl
        , NativeFile
        , Error(..)
        , readAsTextFile
        , readAsArrayBuffer
        , readAsDataUrl
        , prettyPrint
        , parseSelectedFiles
        , parseDroppedFiles
        , filePart
        , rawBody
        )

{-| Elm bindings for the main [HTML5 FileReader APIs](https://developer.mozilla.org/en/docs/Web/API/FileReader):

    FileReaderInstance.readAsText();
    FileReaderInstance.readAsArrayBuffer();
    FileReaderInstance.readAsDataURL();

The module also provides helper Json Decoders for the files values on
`<Input type="file">` `change` events, and on `drop` events,
together with a set of examples.


# API functions

@docs readAsTextFile, readAsArrayBuffer, readAsDataUrl


# Multi-part support

@docs filePart, rawBody


# Helper aliases

@docs NativeFile, FileRef, FileContentArrayBuffer, FileContentDataUrl, Error, prettyPrint


# Helper Json Decoders

@docs parseSelectedFiles, parseDroppedFiles

-}

import Native.FileReader
import Http exposing (Part, Body)
import Task exposing (Task, fail)
import Json.Decode as Json exposing (Decoder, Value)
import MimeType


{-| A FileRef (or Blob) is a Elm Json Value.
-}
type alias FileRef =
    Value


{-| An ArrayBuffer is a Elm Json Value.
-}
type alias FileContentArrayBuffer =
    Value


{-| A DataUrl is an Elm Json Value.
-}
type alias FileContentDataUrl =
    Value


{-| FileReader can fail in the following cases:

  - the File reference / blob passed in was not valid
  - an native error occurs during file reading
  - readAsTextFile is passed a FileRef that does not have a text format (unrecognised formats are read)

-}
type Error
    = NoValidBlob
    | ReadFail
    | NotTextFile


{-| Takes a "File" or "Blob" JS object as a Json.Value. If the File is a text
format, returns a task that reads the file as a text file. The Success value is
represented as a String to Elm.

    readAsTextFile ref

-}
readAsTextFile : FileRef -> Task Error String
readAsTextFile fileRef =
    if isTextFile fileRef then
        Native.FileReader.readAsTextFile fileRef
    else
        fail NotTextFile


{-| Takes a "File" or "Blob" JS object as a Json.Value
and starts a task to read the contents as an ArrayBuffer.
The ArrayBuffer value returned in the Success case of the Task will
be represented as a Json.Value to Elm.

    readAsArrayBuffer ref

-}
readAsArrayBuffer : FileRef -> Task Error FileContentArrayBuffer
readAsArrayBuffer fileRef =
    Native.FileReader.readAsArrayBuffer fileRef


{-| Takes a "File" or "Blob" JS object as a Json.Value
and starts a task to read the contents as an DataURL (so it can
be assigned to the src property of an img e.g.).
The DataURL value returned in the Success case of the Task will
be represented as a Json.Value to Elm.

    readAsDataUrl ref

-}
readAsDataUrl : FileRef -> Task Error FileContentDataUrl
readAsDataUrl fileRef =
    Native.FileReader.readAsDataUrl fileRef


{-| Creates an Http.Part from a NativeFile, to support uploading of binary files using multipart.
-}
filePart : String -> NativeFile -> Part
filePart name nf =
    Native.FileReader.filePart name nf.blob


{-| Creates an Http.Body from a NativeFile, to support uploading of binary files without using multipart.
-}
rawBody : String -> NativeFile -> Body
rawBody mimeType nf =
    Native.FileReader.rawBody mimeType nf.blob


{-| Pretty print FileReader errors.

    prettyPrint ReadFail   -- == "File reading error"

-}
prettyPrint : Error -> String
prettyPrint err =
    case err of
        ReadFail ->
            "File reading error"

        NoValidBlob ->
            "Blob was not valid"

        NotTextFile ->
            "Not a text file"


{-| Helper type for interpreting the Files event value from Input and drag 'n drop.
The first three elements are useful meta data, while the fourth is the handle
needed to read the file.

    type alias NativeFile =
        { name : String
        , size : Int
        , mimeType : Maybe MimeType.MimeType
        , blob : Value
        }

-}
type alias NativeFile =
    { name : String
    , size : Int
    , mimeType : Maybe MimeType.MimeType
    , blob : FileRef
    }


{-| Parse change event from an HTML input element with 'type="file"'.
Returns a list of files.

    onchange : (List NativeFile -> Action) -> Signal.Address Action -> Html.Attribute
    onchange address actionCreator =
        on
            "change"
            parseSelectedFiles
            (\vals -> Signal.message address (actionCreator vals))

-}
parseSelectedFiles : Decoder (List NativeFile)
parseSelectedFiles =
    fileParser "target"


{-| Parse files selected using an HTML drop event.
Returns a list of files.

    ondrop : (List NativeFile -> Action) -> Signal.Address Action -> Html.Attribute
    ondrop actionCreator address =
        onWithOptions
            "drop"
            { stopPropagation = True, preventDefault = True }
            parseDroppedFiles
            (\vals -> Signal.message address (actionCreator vals))

-}
parseDroppedFiles : Decoder (List NativeFile)
parseDroppedFiles =
    --     at [ "dataTransfer", "files" ] (list value)
    fileParser "dataTransfer"



-- UN-EXPORTED HELPERS


{-| -- Used by readAsText, defaults to True if format not recognised
-}
isTextFile : FileRef -> Bool
isTextFile fileRef =
    case Json.decodeValue mtypeDecoder fileRef of
        Result.Ok mimeVal ->
            case mimeVal of
                Just mimeType ->
                    case mimeType of
                        MimeType.Text text ->
                            True

                        _ ->
                            False

                Nothing ->
                    True

        Result.Err _ ->
            False



{- DECODERS
   The Files event has a structure

       { 1 : file1..., 2: file2..., 3 : ... }

   It also inherits other properties that we need to ignore during parsing.
   fileParser achieves this by using Json.maybe and then filtering out Nothing(s)
-}


fileParser : String -> Decoder (List NativeFile)
fileParser fieldName =
    Json.field fieldName <|
        Json.field "files" <|
            fileListDecoder nativeFileDecoder


{-| Apply a decoder to each file in the FileList, in order.
-}
fileListDecoder : Decoder a -> Decoder (List a)
fileListDecoder decoder =
    let
        decodeFileValues indexes =
            indexes
                |> List.map (\index -> Json.field (toString index) decoder)
                |> List.foldr (Json.map2 (::)) (Json.succeed [])
    in
        Json.field "length" Json.int
            |> Json.map (\i -> List.range 0 (i - 1))
            |> Json.andThen decodeFileValues


{-| mime type: parsed as string and then converted to a MimeType
-}
mtypeDecoder : Decoder (Maybe MimeType.MimeType)
mtypeDecoder =
    Json.map MimeType.parseMimeType (Json.field "type" Json.string)


{-| blob: the whole JS File object as a Json.Value so we can pass
it to a library that reads the content with a native FileReader
-}
nativeFileDecoder : Decoder NativeFile
nativeFileDecoder =
    Json.map4 NativeFile
        (Json.field "name" Json.string)
        (Json.field "size" Json.int)
        mtypeDecoder
        Json.value
