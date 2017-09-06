module Instance.Edit exposing (..)

import BranchSelector as BS
import Instance exposing (..)
import Types.RemoteData exposing (RemoteData(..))
import Utils exposing (warningMessage, put, delete)

import Html exposing (..)
import Html.Attributes exposing ( class, defaultValue, list, maxlength
                                , id, value, size, style, type_)
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
  , state : String
  , repositories : List RepoModel
  , requesting : Bool
  , result : RemoteData String String
  }

type ButtonAction
  = Rename String
  | Deploy (List (RepoName, String))
  | Terminate

type Msg
  = Name String
  | BranchSelector RepoName BS.Msg
  | Push String ButtonAction
  | FetchResult (Result Http.Error String)
  | FetchInstance (Result Http.Error Instance)

-- type Msg
--   = Name String
--   | Rename String String
--   | Terminate String
--   | BranchSelector RepoName BS.Msg
--   | FetchInstance (Result Http.Error Instance)
--   | FetchRename (Result Http.Error String)
--   | FetchTerminate (Result Http.Error String)
--   | FetchResultDeployEnv (Result Http.Error String)
--   | RequestToDeployEnv String (List (RepoName, String))

init : Instance -> (Model, Cmd Msg)
init = flip initModel model . .id

model : Model
model =
  { instance = NotRequested
  , name = ""
  , state = ""
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

fetchResult : String -> ButtonAction -> Cmd Msg
fetchResult instanceId = Http.send FetchResult . toRequest instanceId

toRequest : String -> ButtonAction -> Http.Request String
toRequest instanceId action =
  case action of
    Rename name ->
      put ("/api/instance/" ++ instanceId ++ "/rename/" ++ name) Http.emptyBody string
    Deploy branchNames ->
      let
        body = Http.multipartBody $ List.map (uncurry Http.stringPart) branchNames
      in
        put ("/api/instance/" ++ instanceId) body string
    Terminate ->
      delete ("/api/instance/" ++ instanceId) string

view : String -> Model -> Html Msg
view instanceId model =
  div [ class "container mt-4" ]
      [ div [ class "Subhead" ]
            [ h2 [ class "Subhead-heading"] [ text "Edit an exist instance" ]
            , p  [ class "Subhead-description"]
                 [ text "An instance is an environment in which behavior varies depending on the branch you select." ]
            ]
      , viewRename instanceId model
      , hr [] []
      , viewRedeploy instanceId model
      , hr [] []
      , viewControlState instanceId model
      , div [ id "result" ] (viewResult model)
      ]

viewRename : String -> Model -> Html Msg
viewRename instanceId model =
  dl [ class "form-group" ]
     [ dt [] [ label [] [ text "Name" ] ]
     , dt [] [ input [ class "form-control short"
                     , maxlength 255
                     , size 255
                     , type_ "text"
                     , onInput Name
                     , defaultValue model.name
                     ] []
             , viewButton "Rename" "" True (Push instanceId $ Rename model.name) model
             ]
     ]

viewRedeploy : String -> Model -> Html Msg
viewRedeploy instanceId model =
  dl [ class "form-group" ]
     [ dt [] [ label [] [ text "Deploy" ] ]
     , dt [] [ div [ id "repo-branches" ] (viewContent model)
             , viewDeployButton instanceId model
             ]
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

viewButton : String -> String -> Bool -> Msg -> Model -> Html Msg
viewButton txt classTxt flag msg model =
  button [ class "btn"
         , class classTxt
         , if not model.requesting && flag then class "" else class "disabled"
         , onClick msg
         ]
         [ text txt ]

viewDeployButton : String -> Model -> Html Msg
viewDeployButton instanceId model =
  let
    repoToTuple repo = (repo.name, repo.branchModel.selectBranchName)
    flag = List.foldl (&&) True . (::) (model.name /= "")
         $ List.map (\repo -> repo.branchModel.selectBranchName /= "") model.repositories
    msg = Push instanceId . Deploy $ List.map repoToTuple model.repositories
  in
    div [] [ viewButton "Deploy instance" "btn-primary mt-2" flag msg model ]

viewControlState : String -> Model -> Html Msg
viewControlState instanceId model =
  dl [ class "form-group" ]
     [ dt [] [ label [] [ text "Control Instance State" ]
             , viewState model.state
             ]
     , dt [] [ ul [] [ viewTerminate instanceId model ] ]
     ]

viewTerminate : String -> Model -> Html Msg
viewTerminate instanceId model =
  li [ class "Box-row one-half" ]
     [ viewButton "Terminate" "btn-danger boxed-action" True (Push instanceId Terminate) model
     , strong [] [ text "Terminate Instance" ]
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

viewState : String -> Html msg
viewState state =
  let
    viewState_ st txt =
      span [ class "state mx-3", style [("backgroundColor", stateColor st)] ]
           [ text txt ]
  in
    case state of
      "running" -> viewState_ state "Running"
      "pending" -> viewState_ state "Pending"
      "shutting-down" -> viewState_ state "Shutting-down"
      "terminated" -> viewState_ state "Terminated"
      "stopping" -> viewState_ state "Stopping"
      "stopped" -> viewState_ state "Stopped"
      _ -> span [] []

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Name name -> ({ model | name = name }, Cmd.none)
    -- Rename instanceId name -> ({ model | requesting = True }, fetchRename instanceId name)
    -- Terminate instanceId -> (model, fetchTerminate instanceId)
    BranchSelector repoName branchMsg ->
      case List.find (\repo -> repo.name == repoName) model.repositories of
        Just repo ->
          flip (updateRepo repoName) model *** Cmd.map (BranchSelector repoName)
          $ BS.update branchMsg repo.branchModel
        Nothing ->
          ({ model | result = Failure "repo is not found..." }, Cmd.none)
    Push instanceId action ->
      ({ model | requesting = True }, fetchResult instanceId action)
    FetchInstance (Ok instance) -> (updateInstance instance model, Cmd.none)
    FetchInstance (Err error) ->
      ({ model | instance = Failure "Something went wrong..." }, Cmd.none)
    FetchResult (Ok response) ->
      ({ model | requesting = False, result = Success response }, Cmd.none)
    FetchResult (Err error) ->
      ({ model | requesting = False, result = Failure "Something went wrong..." }, Cmd.none)
    -- RequestToDeployEnv instanceId branches ->
    --   ({ model | requesting = True }, fetchResult instanceId branches)

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
  , state = instance.state
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
