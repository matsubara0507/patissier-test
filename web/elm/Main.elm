module Main exposing (..)

import Debug exposing (crash)
import Html exposing (..)
import Html.Attributes exposing (class, list, id)
import Html.Events exposing (..)
import Http
import Json.Decode as JD exposing (succeed, field, string)
import Json.Decode.Extra exposing ((|:))

main : Program Never Model Msg
main = program
     { init = init
     , view = view
     , update = update
     , subscriptions = always <| Sub.none
     }

type alias Model =
  { branches : RemoteData String Branches
  }

type alias Branches = List Branch

type alias Branch = { name : String }

type RemoteData e a
  = NotRequested
  | Requesting
  | Failure e
  | Success a

type Msg
  = FetchResult (Result Http.Error Branches)

branchesDecorder : JD.Decoder Branches
branchesDecorder = succeed Branch
                 |: (field "name" string)
                 |> JD.list

init : (Model, Cmd Msg)
init = initModel model

model : Model
model = { branches = NotRequested }

initModel : Model -> (Model, Cmd Msg)
initModel model = model ! [ fetchBranch "/elixir-lang/elixir" ]

fetchBranch : String -> Cmd Msg
fetchBranch path =
  let
    apiUrl = "https://api.github.com/repos" ++ path ++ "/branches"
          -- ++ "?access_token=xxx"
    request = Http.get apiUrl branchesDecorder
  in
    Http.send FetchResult request

view : Model -> Html Msg
view model =
  div
    [ id "repo-branches" ]
    (viewContent model)

viewContent : Model -> List (Html Msg)
viewContent model =
  case model.branches of
    NotRequested ->
      [ text "" ]
    Requesting ->
      [ warningMessage
          "fa fa-spin fa-cog fa-2x fa-fw"
          "getting branches"
          (text "")
      ]
    Failure error ->
      [ warningMessage
          "fa fa-meh-o fa-stack-2x"
          error
          (text "")
      ]
    Success page ->
      [ ul [ class "branch-list" ]
          <| List.map viewBranch page
      ]

viewBranch : Branch -> Html msg
viewBranch branch =
  li [] [ text branch.name ]

warningMessage : String -> String -> Html Msg -> Html Msg
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

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    FetchResult (Ok response) ->
      { model | branches = Success response } ! []
    FetchResult (Err error) ->
      { model | branches = Failure "Something went wrong..." } ! []

undefined : () -> a
undefined _ = crash "Undefined!"
