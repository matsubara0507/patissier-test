module Instance.Edit exposing (..)

import BranchSelector as BS
import Instance exposing (..)
import Types.RemoteData exposing (RemoteData(..))
import Utils exposing (warningMessage, put)

import Html exposing (..)
import Html.Attributes exposing ( class, defaultValue, list, maxlength
                                , id, value, size, type_)
import Html.Events exposing (..)
import Http
import Json.Decode as JD exposing (string)
import List.Extra as List

import Data.Composition exposing (..)

type alias RepoName = String
type alias RepoModel = { name : RepoName, branchModel : BS.Model }

type alias Model =
  { instance : RemoteData String Instance
  , name : String
  , repositories : List RepoModel
  , requesting : Bool
  , result : RemoteData String String
  }

type Msg
  = Name String
  | Rename String String
  | BranchSelector RepoName BS.Msg
  | FetchInstance (Result Http.Error Instance)
  | FetchRename (Result Http.Error String)
  | FetchResultDeployEnv (Result Http.Error String)
  | RequestToDeployEnv String (List (RepoName, String))

init : Instance -> (Model, Cmd Msg)
init = flip initModel model . .id

model : Model
model =
  { instance = NotRequested
  , name = ""
  , repositories =
      [ { name = "html-dump1", branchModel = BS.model }
      , { name = "html-dump2", branchModel = BS.model }
      ]
  , requesting = False
  , result = NotRequested
  }

initModel : String -> Model -> (Model, Cmd Msg)
initModel instanceId model =
  ( model
  , model.repositories
    |> List.map (\repo -> Cmd.map (BranchSelector repo.name) $ BS.fetchBranch "")
    |> (::) (fetchInstance instanceId)
    |> Cmd.batch
  )

fetchInstance : String -> Cmd Msg
fetchInstance instanceId =
  let
    apiUrl = "/api/instance/" ++ instanceId
    request = Http.get apiUrl instanceDecoder
  in
    Http.send FetchInstance request

fetchResult : String -> List (RepoName, String) -> Cmd Msg
fetchResult instanceId branchNames =
  let
    apiUrl = "/api/instance/" ++ instanceId
    body =
      Http.multipartBody
      <| List.map (uncurry Http.stringPart) branchNames
    request = put apiUrl body string
  in
    Http.send FetchResultDeployEnv request

fetchRename : String -> String -> Cmd Msg
fetchRename instanceId instanceName =
  let
    apiUrl = "/api/instance/" ++ instanceId ++ "/rename/" ++ instanceName
    request = put apiUrl Http.emptyBody string
  in
    Http.send FetchRename request

view : String -> Model -> Html Msg
view instanceId model =
  div [ class "container mt-4" ]
      [ div [ class "Subhead" ]
            [ h2 [ class "Subhead-heading"] [ text "Edit an exist instance" ]
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
                           , defaultValue model.name
                           ] []
                   , button [ class "btn"
                            , if not model.requesting then class "" else class "disabled"
                            , onClick $ Rename instanceId model.name
                            ]
                            [ text "Rename" ]
                   ]
            ]
      , div [ id "repo-branches" ] (viewContent model)
      , viewDeployButton instanceId model
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

viewDeployButton : String -> Model -> Html Msg
viewDeployButton instanceId model =
  let
    repoToTuple repo = (repo.name, repo.branchModel.selectBranchName)
    flag = List.foldl (&&) True . (::) (model.name /= "")
         $ List.map (\repo -> repo.branchModel.selectBranchName /= "") model.repositories
  in
    div []
      [ hr [] []
      , button [ class "btn btn-primary"
               , if not model.requesting && flag then class "" else class "disabled"
               , onClick . RequestToDeployEnv instanceId
                 $ List.map repoToTuple model.repositories
               ]
               [ text "Deploy instance" ]
      ]


viewResult : Model -> List (Html Msg)
viewResult model =
  case model.result of
    NotRequested ->
      [ text "" ]
    Requesting ->
      [ warningMessage "" "Requesting" (text "") ]
    Failure error ->
      [ warningMessage "" error (text "") ]
    Success page ->
      [ div [ class "flash mt-3" ] [ text page ] ]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Name name -> ({ model | requesting = True, name = name }, Cmd.none)
    Rename instanceId name -> (model, fetchRename instanceId name)
    BranchSelector repoName branchMsg ->
      case List.find (\repo -> repo.name == repoName) model.repositories of
        Just repo ->
          flip (updateRepo repoName) model *** Cmd.map (BranchSelector repoName)
          $ BS.update branchMsg repo.branchModel
        Nothing ->
          ({ model | result = Failure "repo is not found..." }, Cmd.none)
    FetchInstance (Ok instance) -> (updateInstance instance model, Cmd.none)
    FetchInstance (Err error) ->
      ({ model | instance = Failure "Something went wrong..." }, Cmd.none)
    FetchRename (Ok response) ->
      ({ model | requesting = False, result = Success response }, Cmd.none)
    FetchRename (Err error) ->
      ({ model | requesting = False, result = Failure "Something went wrong..." }, Cmd.none)
    FetchResultDeployEnv (Ok response) ->
      ({ model | requesting = False, result = Success response }, Cmd.none)
    FetchResultDeployEnv (Err error) ->
      ({ model | requesting = False, result = Failure "Something went wrong..." }, Cmd.none)
    RequestToDeployEnv instanceId branches ->
      ({ model | requesting = True }, fetchResult instanceId branches)

updateRepo : RepoName -> BS.Model -> Model -> Model
updateRepo repoName branchModel model =
  let
    repo = { name = repoName, branchModel = branchModel }
    repositories_ =
      List.replaceIf (\r -> r.name == repoName) repo model.repositories
  in
    { model | repositories = repositories_ }

updateInstance : Instance -> Model -> Model
updateInstance instance model =
  { model
  | instance = Success instance
  , name = getInstanceName instance
  , repositories = List.map (updateSelectBranch instance) model.repositories
  }

updateSelectBranch : Instance -> RepoModel -> RepoModel
updateSelectBranch instance ({ branchModel } as repo) =
  let
    replaceString a b = String.map (\c -> if c == a then b else c)
    selectBranchName =
      List.find (\t -> t.key == replaceString '-' '_' repo.name) instance.tags
      |> Maybe.map .value
      |> Maybe.withDefault ""
    branchModel_ = { branchModel | selectBranchName = selectBranchName }
  in
    { repo | branchModel = branchModel_ }
