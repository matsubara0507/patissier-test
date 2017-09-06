module Utils exposing (..)

import Debug exposing (crash)
import Html exposing (..)
import Html.Attributes exposing (class, list, id, value)
import Http exposing (..)
import Json.Decode exposing (Decoder)

warningMessage : String -> String -> Html msg -> Html msg
warningMessage iconClasses message content =
    div
        [ class "flash flash-error mt-3" ]
        [ span
            [ class "fa-stack" ]
            [ i [ class iconClasses ] [] ]
        , h4
            []
            [ text message ]
        , content
        ]

put : String -> Body -> Decoder a -> Request a
put url body decoder =
  Http.request
    { method = "PUT"
    , headers = []
    , url = url
    , body = body
    , expect = Http.expectJson decoder
    , timeout = Nothing
    , withCredentials = False
    }

delete : String -> Decoder a -> Request a
delete url decoder =
  Http.request
    { method = "DELETE"
    , headers = []
    , url = url
    , body = emptyBody
    , expect = Http.expectJson decoder
    , timeout = Nothing
    , withCredentials = False
    }

undefined : () -> a
undefined _ = crash "Undefined!"
