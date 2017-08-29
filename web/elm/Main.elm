module Main exposing (..)

import BranchSelector as BS
import Types.RemoteData exposing (RemoteData(..))
import Utils exposing (warningMessage)

import Html exposing (..)
import Html.Attributes exposing (class, list, id, value)
import Html.Events exposing (..)
import Http
import Json.Decode as JD exposing (string)

import Data.Composition exposing (..)

main : Program Never Model Msg
main = program
     { init = init
     , view = view
     , update = update
     , subscriptions = always <| Sub.none
     }

type alias RepoModel =
  { name : String
  , branchModel : BS.Model
  }

type alias Model =
  { repository : RepoModel
  , result : RemoteData String String
  }

type Msg
  = BranchSelector BS.Msg
  | FetchResultCreateEnv (Result Http.Error String)
  | RequestToCreateEnv String

init : (Model, Cmd Msg)
init = initModel model

model : Model
model =
  { repository =
    { name = "html-dump"
    , branchModel = BS.model
    }
  , result = NotRequested
  }

initModel : Model -> (Model, Cmd Msg)
initModel model =
  ( model
  , Cmd.map BranchSelector $ BS.fetchBranch ""
  )

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

viewContent : Model -> List (Html Msg)
viewContent model =
  [ Html.map BranchSelector
    $ BS.view model.repository.name model.repository.branchModel
  , button [ onClick (RequestToCreateEnv model.repository.branchModel.selectBranchName) ]
           [ text "request!" ]
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

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    BranchSelector branchMsg ->
      flip updateRepo model *** Cmd.map BranchSelector
      $ BS.update branchMsg model.repository.branchModel
    FetchResultCreateEnv (Ok response) ->
      ({ model | result = Success response }, Cmd.none)
    FetchResultCreateEnv (Err error) ->
      ({ model | result = Failure "Something went wrong..." }, Cmd.none)
    RequestToCreateEnv branch ->
      (model, Cmd.batch [ fetchResult branch ])

updateRepo : BS.Model -> Model -> Model
updateRepo branchModel model =
  let
    repository_ = model.repository
  in
    { model | repository = { repository_ | branchModel = branchModel } }
