module Controller.Keyboard exposing (..)

import Keyboard exposing (..)
import Dict exposing (..)


type Direction
    = Up
    | Down
    | Left
    | Right


type Msg
    = Move Direction


subscriptions : Sub (Maybe Msg)
subscriptions =
    presses keycodeToMsg


playerKeymap : Dict Int Direction
playerKeymap =
    Dict.fromList
        [ ( 87, Up )
        , ( 119, Up )
        , ( 83, Down )
        , ( 115, Down )
        , ( 65, Left )
        , ( 97, Left )
        , ( 68, Right )
        , ( 100, Right )
        ]


keycodeToMsg : Keyboard.KeyCode -> Maybe Msg
keycodeToMsg code =
    playerKeymap |> Dict.get code |> Maybe.map Move