module Instance.New exposing (..)

import BranchSelector as BS
import Types.RemoteData exposing (RemoteData(..))
import Utils exposing (warningMessage)

import Html exposing (..)
import Html.Attributes exposing (class, list, id, value)
import Html.Events exposing (..)
import Http
import Json.Decode as JD exposing (string)
import List.Extra as List

import Data.Composition exposing (..)

type alias RepoName = String
type alias RepoModel = { name : RepoName, branchModel : BS.Model }

type alias Model =
  { repositories : List RepoModel
  , result : RemoteData String String
  }

type Msg
  = BranchSelector RepoName BS.Msg
  | FetchResultCreateEnv (Result Http.Error String)
  | RequestToCreateEnv (List (RepoName, String))

init : (Model, Cmd Msg)
init = initModel model

model : Model
model =
  { repositories =
      [ { name = "html-dump1", branchModel = BS.model }
      , { name = "html-dump2", branchModel = BS.model }
      ]
  , result = NotRequested
  }

initModel : Model -> (Model, Cmd Msg)
initModel model =
  ( model
  , model.repositories
    |> List.map (\repo -> Cmd.map (BranchSelector repo.name) $ BS.fetchBranch "")
    |> Cmd.batch
  )

fetchResult : List (RepoName, String) -> Cmd Msg
fetchResult branchNames =
  let
    apiUrl = "/api/branches"
    body =
      Http.multipartBody
      $ List.map (uncurry Http.stringPart) branchNames
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
  let
    viewRepo repo =
      Html.map (BranchSelector repo.name) $ BS.view repo.name repo.branchModel
    repoToTuple repo = (repo.name, repo.branchModel.selectBranchName)
  in
    [ div [] $ List.map viewRepo model.repositories
    , button
        [ onClick . RequestToCreateEnv $ List.map repoToTuple model.repositories ]
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
    BranchSelector repoName branchMsg ->
      case List.find (\repo -> repo.name == repoName) model.repositories of
        Just repo ->
          flip (updateRepo repoName) model *** Cmd.map (BranchSelector repoName)
          $ BS.update branchMsg repo.branchModel
        Nothing ->
          ({ model | result = Failure "repo is not found..." }, Cmd.none)
    FetchResultCreateEnv (Ok response) ->
      ({ model | result = Success response }, Cmd.none)
    FetchResultCreateEnv (Err error) ->
      ({ model | result = Failure "Something went wrong..." }, Cmd.none)
    RequestToCreateEnv branches ->
      (model, fetchResult branches)

updateRepo : RepoName -> BS.Model -> Model -> Model
updateRepo repoName branchModel model =
  let
    repo = { name = repoName, branchModel = branchModel }
    repositories_ =
      List.replaceIf (\r -> r.name == repoName) repo model.repositories
  in
    { model | repositories = repositories_ }
