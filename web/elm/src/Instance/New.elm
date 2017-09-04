module Instance.New exposing (..)

import BranchSelector as BS
import Types.RemoteData exposing (RemoteData(..))
import Utils exposing (warningMessage)

import Html exposing (..)
import Html.Attributes exposing (class, list, maxlength, id, value, size, type_)
import Html.Events exposing (..)
import Http
import Json.Decode as JD exposing (string)
import List.Extra as List

import Data.Composition exposing (..)

type alias RepoName = String
type alias RepoModel = { name : RepoName, branchModel : BS.Model }

type alias Model =
  { name : String
  , repositories : List RepoModel
  , result : RemoteData String String
  }

type Msg
  = Name String
  | BranchSelector RepoName BS.Msg
  | FetchResultCreateEnv (Result Http.Error String)
  | RequestToCreateEnv String (List (RepoName, String))

init : (Model, Cmd Msg)
init = initModel model

model : Model
model =
  { name = ""
  , repositories =
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

fetchResult : String -> List (RepoName, String) -> Cmd Msg
fetchResult instanceName branchNames =
  let
    apiUrl = "/api/branches"
    body =
      Http.multipartBody
      <| (::) (Http.stringPart "name" instanceName)
      <| List.map (uncurry Http.stringPart) branchNames
    request = Http.post apiUrl body string
  in
    Http.send FetchResultCreateEnv request

view : Model -> Html Msg
view model =
  div [ class "container mt-4" ]
      [ div [ class "Subhead" ]
            [ h2 [ class "Subhead-heading"] [ text "Create an new instance" ]
            , p  [ class "Subhead-description"]
                 [ text "An instance is an environment in which behavior varies depending on the branch you select." ]
            ]
      , dl [ class "form-group" ]
           [ dt [] [ label [] [ text "Name" ] ]
           , dt [] [ input [ class "form-control short"
                           , maxlength 255
                           , size 255
                           , type_ "text"
                           , onInput Name
                           ] [] ]
            ]
      , div [ id "repo-branches" ] (viewContent model)
      , viewCreateButton model
      , div [ id "result" ] (viewResult model)
      ]

viewContent : Model -> List (Html Msg)
viewContent model =
  let
    viewRepo repo =
      Html.map (BranchSelector repo.name) $ BS.view repo.name repo.branchModel
  in
    [ table [ class "bspace" ]
            [ thead [] [ tr [] [ td [] [ label [] [ text "repository: ", br [] [] ] ]
                               , td [] [ label [] [ text "branch" ] ]
                               ] ]
            , tbody [] $ List.map viewRepo model.repositories
            ]
    ]

viewCreateButton : Model -> Html Msg
viewCreateButton model =
  let
    repoToTuple repo = (repo.name, repo.branchModel.selectBranchName)
    flag = List.foldl (&&) True . (::) (model.name /= "")
         $ List.map (\repo -> repo.branchModel.selectBranchName /= "") model.repositories
  in
    div []
      [ hr [] []
      , button [ class "btn btn-primary"
               , if flag then class "" else class "disabled"
               , onClick . RequestToCreateEnv model.name
                 $ List.map repoToTuple model.repositories
               ]
               [ text "Create instance" ]
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
    Name name -> ({ model | name = name }, Cmd.none)
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
    RequestToCreateEnv name branches ->
      (model, fetchResult name branches)

updateRepo : RepoName -> BS.Model -> Model -> Model
updateRepo repoName branchModel model =
  let
    repo = { name = repoName, branchModel = branchModel }
    repositories_ =
      List.replaceIf (\r -> r.name == repoName) repo model.repositories
  in
    { model | repositories = repositories_ }
