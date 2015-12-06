{- TO BE MOVED TO LIBRARY BEFORE PUBLICATION -}

module MimeHelpers
  ( MimeImage
  , MimeAudio
  , MimeVideo
  , MimeText
  , MimeType(Image, Audio, Video, Text, OtherMimeType)
  , parseMimeType) where
-- This is an incomplete, somewhat arbitrary mapping of the most common browser mime types to custom types.
-- See https://code.google.com/p/chromium/codesearch#chromium/src/net/base/mime_util.cc&l=201 for a full list of Mime types

import String

type MimeImage
  = Jpeg
  | Png
  | Gif
  | OtherImage

type MimeAudio
  = Mp3
  | Ogg
  | Wav
  | OtherAudio

type MimeVideo
  = Mp4
  | Mpeg
  | Quicktime
  | Avi
  | Webm
  | OtherVideo

type MimeText
  = PlainText
  | Html
  | Css
  | Xml
  | Json
  | OtherText

type MimeType =
  Image MimeImage
  | Audio MimeAudio
  | Video MimeVideo
  | Text MimeText
  | OtherMimeType

parseMimeType: String -> Maybe MimeType
parseMimeType mimeString =
  case (String.toLower mimeString) of
    "" -> Nothing
    "image/jpeg" -> Just <| Image Jpeg
    "image/png" -> Just <| Image Png
    "image/gif" -> Just <| Image Gif
    "audio/mp3" -> Just <| Audio Mp3
    "audio/wav" -> Just <| Audio Wav
    "audio/ogg" -> Just <| Audio Ogg
    "video/mp4" -> Just <| Video Mp4
    "video/mpeg" -> Just <| Video Mpeg
    "video/quicktime" -> Just <| Video Quicktime
    "video/avi" -> Just <| Video Avi
    "video/webm" -> Just <| Video Webm
    "text/plain" -> Just <| Text PlainText
    "text/html" -> Just <| Text Html
    "text/css" -> Just <| Text Css
    "text/xml" -> Just <| Text Xml
    "application/json" -> Just <| Text Json
    lowerCaseMimeString ->
      if (String.startsWith "image" lowerCaseMimeString) then
        Just <| Image OtherImage
      else if (String.startsWith "audio" lowerCaseMimeString) then
        Just <| Audio OtherAudio
      else if (String.startsWith "video" lowerCaseMimeString) then
        Just <| Video OtherVideo
      else if (String.startsWith "text" lowerCaseMimeString) then
        Just <| Text OtherText
      else
        Just OtherMimeType
