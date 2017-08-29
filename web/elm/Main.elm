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
  { repository1 : RepoModel
  , repository2 : RepoModel
  , result : RemoteData String String
  }

type Msg
  = BranchSelector1 BS.Msg
  | BranchSelector2 BS.Msg
  | FetchResultCreateEnv (Result Http.Error String)
  | RequestToCreateEnv String String

init : (Model, Cmd Msg)
init = initModel model

model : Model
model =
  { repository1 =
    { name = "html-dump1"
    , branchModel = BS.model
    }
  , repository2 =
    { name = "html-dump2"
    , branchModel = BS.model
    }
  , result = NotRequested
  }

initModel : Model -> (Model, Cmd Msg)
initModel model =
  ( model
  , Cmd.batch
      [ Cmd.map BranchSelector1 $ BS.fetchBranch ""
      , Cmd.map BranchSelector2 $ BS.fetchBranch ""
      ]
  )

fetchResult : String -> String -> Cmd Msg
fetchResult branchName1 branchName2 =
  let
    apiUrl = "/api/branches"
    body = Http.multipartBody
      [ Http.stringPart "branch1" branchName1
      , Http.stringPart "branch2" branchName2
      ]
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
  [ Html.map BranchSelector1
    $ BS.view model.repository1.name model.repository1.branchModel
  , Html.map BranchSelector2
    $ BS.view model.repository2.name model.repository2.branchModel
  , button [ onClick (RequestToCreateEnv
                        model.repository1.branchModel.selectBranchName
                        model.repository2.branchModel.selectBranchName)
            ]
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
    BranchSelector1 branchMsg ->
      (\m -> { model | repository1 = updateRepo m model.repository1 })
        *** Cmd.map BranchSelector1
      $ BS.update branchMsg model.repository1.branchModel
    BranchSelector2 branchMsg ->
      (\m -> { model | repository2 = updateRepo m model.repository2 })
        *** Cmd.map BranchSelector2
      $ BS.update branchMsg model.repository2.branchModel
    FetchResultCreateEnv (Ok response) ->
      ({ model | result = Success response }, Cmd.none)
    FetchResultCreateEnv (Err error) ->
      ({ model | result = Failure "Something went wrong..." }, Cmd.none)
    RequestToCreateEnv branch1 branch2 ->
      (model, Cmd.batch [ fetchResult branch1 branch2 ])

updateRepo : BS.Model -> RepoModel -> RepoModel
updateRepo branchModel repo = { repo | branchModel = branchModel }
