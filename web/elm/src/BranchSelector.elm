module BranchSelector exposing (..)

import Types.RemoteData exposing (RemoteData(..))
import Utils exposing (warningMessage)

import Html exposing (..)
import Html.Attributes exposing (class, list, id, selected, value)
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
      warningMessage "" "getting branches" (text "")
    Failure error ->
      warningMessage "f" error (text "")
    Success page -> selectBranch repoName model.selectBranchName page

selectBranch : String -> String -> Branches -> Html Msg
selectBranch repoName selectBranchName branches =
  tr
      [ onInput ChangeSelectBranchName ]
      [ td [] [ text $ repoName ++ ": ", br [] [] ]
      , td []
           [ select [ class "form-select select-sm", id repoName ]
              <| List.map (viewBranch selectBranchName) branches
           ]
      ]

viewBranch : String -> Branch -> Html msg
viewBranch selectBranchName branch =
  option [ value branch.name
         , selected $ branch.name == selectBranchName
         ]
         [ text branch.name ]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    FetchBranches (Ok response) ->
      ({ model | branches = Success response }, Cmd.none)
    FetchBranches (Err error) ->
      ({ model | branches = Failure "Something went wrong..." }, Cmd.none)
    ChangeSelectBranchName branchName ->
      ({ model | selectBranchName = branchName }, Cmd.none)
