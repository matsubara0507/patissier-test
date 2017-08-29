module Utils exposing (..)

import Debug exposing (crash)
import Html exposing (..)
import Html.Attributes exposing (class, list, id, value)

warningMessage : String -> String -> Html msg -> Html msg
warningMessage iconClasses message content =
    div
        [ class "warning" ]
        [ span
            [ class "fa-stack" ]
            [ i [ class iconClasses ] [] ]
        , h4
            []
            [ text message ]
        , content
        ]

undefined : () -> a
undefined _ = crash "Undefined!"