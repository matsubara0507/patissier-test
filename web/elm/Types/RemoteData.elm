module Types.RemoteData exposing (..)

type RemoteData e a
  = NotRequested
  | Requesting
  | Failure e
  | Success a
