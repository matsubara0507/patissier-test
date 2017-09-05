module Instance exposing (..)

import Types.RemoteData exposing (RemoteData(..))
import Utils exposing (warningMessage)
import Routes exposing (Sitemap(NewR))

import Json.Decode as JD exposing (succeed, field, string)
import Json.Decode.Extra exposing ((|:))
import List.Extra as List
import Maybe

import Data.Composition exposing (..)

type alias Instance =
  { id : String
  , publicIp : String
  , state : String
  , tags : List Tag
  }
type alias Instances = List Instance

type alias Tag = { key : String, value : String }

instanceDecoder : JD.Decoder Instance
instanceDecoder = succeed Instance
               |: (field "instance_id" string)
               |: (field "public_ip" string)
               |: (field "state" string)
               |: (field "tags" (JD.list tagDecorder))

instancesDecorder : JD.Decoder Instances
instancesDecorder = JD.list instanceDecoder 

tagDecorder : JD.Decoder Tag
tagDecorder = succeed Tag
           |: (field "key" string)
           |: (field "value" string)

stateColor : String -> String
stateColor instanceState =
  case instanceState of
    "pending" -> "yellow"
    "running" -> "lawngreen"
    "shutting-down" -> "yellow"
    "terminated" -> "red"
    "stopping" -> "yellow"
    "stopped" -> "red"
    _ -> "transparent"

getInstanceName : Instance -> String
getInstanceName instance =
  Maybe.withDefault "" . Maybe.map .value
  $ List.find (\t -> t.key == "Name") instance.tags
