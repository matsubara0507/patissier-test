module Instance.List exposing (..)

import Types.RemoteData exposing (RemoteData(..))
import Utils exposing (warningMessage)

import Html exposing (..)
import Html.Attributes exposing (class, list, id, value)
import Html.Events exposing (..)
import Http
import Json.Decode as JD exposing (succeed, field, string)
import Json.Decode.Extra exposing ((|:))

import Data.Composition exposing (..)

type alias Instance =
  { id : String
  , publicIp : String
  , tags : List Tag
  }
type alias Instances = List Instance

type alias Tag = { key : String, value : String }

type alias Model =
  { instances : RemoteData String Instances
  }

type Msg
  = FetchInstances (Result Http.Error Instances)

instancesDecorder : JD.Decoder Instances
instancesDecorder = succeed Instance
                 |: (field "instance_id" string)
                 |: (field "public_ip" string)
                 |: (field "tags" (JD.list tagDecorder))
                 |> JD.list

tagDecorder : JD.Decoder Tag
tagDecorder = succeed Tag
           |: (field "key" string)
           |: (field "value" string)

model : Model
model =
  { instances = NotRequested
  }

fetchInstances : Cmd Msg
fetchInstances =
  let
    apiUrl = "/api/instances"
    request = Http.get apiUrl instancesDecorder
  in
    Http.send FetchInstances request

view : Model -> Html msg
view model =
  case model.instances of
    NotRequested -> text ""
    Requesting ->
      warningMessage "fa fa-spin fa-cog fa-2x fa-fw" "getting branches" (text "")
    Failure error ->
      warningMessage "fa fa-meh-o fa-stack-2x" error (text "")
    Success page -> viewInstances page

viewInstances : Instances -> Html msg
viewInstances = ul [ class "existing-instances" ] . List.map viewInstance

viewInstance : Instance -> Html msg
viewInstance instance =
  li
    [ id instance.id ]
    [ div [] [ text $ instance.id ++ ": " ++ instance.publicIp ]
    , div [ class "tags" ]
      $ List.map (\t -> text $ t.key ++ ":" ++ t.value ++ ", ") instance.tags
    ]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    FetchInstances (Ok response) ->
      ({ model | instances = Success response }, Cmd.none)
    FetchInstances (Err error) ->
      ({ model | instances = Failure $ "Something went wrong....." ++ toString error }, Cmd.none)
