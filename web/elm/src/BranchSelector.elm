module BranchSelector exposing (..)

import Types.RemoteData exposing (RemoteData(..))
import Utils exposing (warningMessage)

import Html exposing (..)
import Html.Attributes exposing (class, list, id, value)
import Html.Events exposing (..)
import Http
import Json.Decode as JD exposing (succeed, field, string)
import Json.Decode.Extra exposing ((|:))

import Data.Composition exposing (..)

type alias Branches = List Branch
type alias Branch = { name : String }

type alias Model =
  { branches : RemoteData String Branches
  , selectBranchName : String
  }

type Msg
  = FetchBranches (Result Http.Error Branches)
  | ChangeSelectBranchName String

branchesDecorder : JD.Decoder Branches
branchesDecorder = succeed Branch
                 |: (field "name" string)
                 |> JD.list

model : Model
model =
  { branches = NotRequested
  , selectBranchName = ""
  }

fetchBranch : String -> Cmd Msg
fetchBranch repo =
  let
    apiUrl = "/api/branches?" ++ repo
    request = Http.get apiUrl branchesDecorder
  in
    Http.send FetchBranches request

view : String -> Model -> Html Msg
view repoName model =
  case model.branches of
    NotRequested -> text ""
    Requesting ->
      warningMessage "fa fa-spin fa-cog fa-2x fa-fw" "getting branches" (text "")
    Failure error ->
      warningMessage "fa fa-meh-o fa-stack-2x" error (text "")
    Success page -> selectBranch repoName page

selectBranch : String -> Branches -> Html Msg
selectBranch repoName branches =
  div
      [ onInput ChangeSelectBranchName ]
      [ span [] [ text $ repoName ++ ": " ]
      , select [ class "branch-list", id repoName ]
          <| (::) (option [ value "" ] [ text "--unselect--" ])
          <| List.map viewBranch branches
      ]

viewBranch : Branch -> Html msg
viewBranch branch =
  option [ value branch.name ] [ text branch.name ]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    FetchBranches (Ok response) ->
      ({ model | branches = Success response }, Cmd.batch [])
    FetchBranches (Err error) ->
      ({ model | branches = Failure "Something went wrong..." }, Cmd.batch [])
    ChangeSelectBranchName branchName ->
      ({ model | selectBranchName = branchName }, Cmd.batch [])
