module Main exposing (..)

import Debug exposing (crash)
import Html exposing (..)
import Html.Attributes exposing (class, list, id, value)
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
  , selectBranchName : String
  , result : RemoteData String String
  }

type alias Branches = List Branch

type alias Branch = { name : String }

type RemoteData e a
  = NotRequested
  | Requesting
  | Failure e
  | Success a

type Msg
  = FetchBranches (Result Http.Error Branches)
  | FetchResultCreateEnv (Result Http.Error String)
  | ChangeSelectBranchName String
  | RequestToCreateEnv String

branchesDecorder : JD.Decoder Branches
branchesDecorder = succeed Branch
                 |: (field "name" string)
                 |> JD.list

init : (Model, Cmd Msg)
init = initModel model

model : Model
model = { branches = NotRequested
        , selectBranchName = ""
        , result = NotRequested
        }

initModel : Model -> (Model, Cmd Msg)
initModel model = model ! [ fetchBranch ]

fetchBranch : Cmd Msg
fetchBranch =
  let
    apiUrl = "/api/branches"
    request = Http.get apiUrl branchesDecorder
  in
    Http.send FetchBranches request

fetchResult : String -> Cmd Msg
fetchResult branchName =
  let
    apiUrl = "/api/branches"
    body = Http.multipartBody [ Http.stringPart "branch" branchName ]
    request = Http.post apiUrl body string
  in
    Http.send FetchResultCreateEnv request

view : Model -> Html Msg
view model =
  div []
    [ div [ id "repo-branches" ] (viewContent model)
    , div [ id "result" ] (viewResult model)
    ]

viewResult : Model -> List (Html Msg)
viewResult model =
  case model.result of
    NotRequested ->
      [ text "" ]
    Requesting ->
      [ warningMessage
          "fa fa-spin fa-cog fa-2x fa-fw"
          "getting branches"
          (text "aaa")
      ]
    Failure error ->
      [ warningMessage
          "fa fa-meh-o fa-stack-2x"
          error
          (text "bbb")
      ]
    Success page ->
      [ div [] [ text page ] ]

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
      [ div []
            [ selectBranch page
            , button [ onClick (RequestToCreateEnv model.selectBranchName) ]
                     [ text "request!" ]
            ]
      ]

selectBranch : Branches -> Html Msg
selectBranch branches =
  div
      [ onInput ChangeSelectBranchName ]
      [ span [] [ text "branch: " ]
      , select [ class "branch-list" ]
          <| (::) (option [ value "" ] [ text "--unselect--" ])
          <| List.map viewBranch branches
      ]

viewBranch : Branch -> Html msg
viewBranch branch =
  option [ value branch.name ] [ text branch.name ]

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
    FetchBranches (Ok response) ->
      { model | branches = Success response } ! []
    FetchBranches (Err error) ->
      { model | branches = Failure "Something went wrong..." } ! []
    FetchResultCreateEnv (Ok response) ->
      { model | result = Success response } ! []
    FetchResultCreateEnv (Err error) ->
      { model | result = Failure "Something went wrong..." } ! []
    ChangeSelectBranchName branchName ->
      { model | selectBranchName = branchName } ! []
    RequestToCreateEnv branch ->
      model ! [ fetchResult branch ]


undefined : () -> a
undefined _ = crash "Undefined!"
