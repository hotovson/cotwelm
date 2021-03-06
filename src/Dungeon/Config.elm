module Dungeon.Config exposing (..)

import Random exposing (..)


{-| This module houses the configuration properties of the dungeon such as dungeon size,
max number of rooms on a floor, all details about the rooms, corridor lengths etc...

The module has no model but rather are mostly a collection of constants used by the
dungeon generator to create random dungeon levels.
-}
type RoomType
    = Rectangular
    | Cross
    | Diamond
    | Potion
    | Circular
    | DiagonalSquares
    | DeadEnd


{-| Width and height dimensions of the dungeon level
-}
size : Int
size =
    30


{-| Maximum allowed width and height dimension of a room. The minimum dimension is
   dependent on the room type (e.g the rectangular room has a minimum of 3 x 3)
-}
roomSize : Int
roomSize =
    10


generateRoomSize : Generator Int
generateRoomSize =
    Random.int 1 10


roomSizeGenerator : RoomType -> Generator Int
roomSizeGenerator roomType =
    case roomType of
        Rectangular ->
            Random.int 4 10

        Cross ->
            Random.int 1 4

        Diamond ->
            Random.int 4 10

        Potion ->
            Random.int 4 10

        Circular ->
            Random.int 4 10

        DiagonalSquares ->
            Random.int 4 10

        DeadEnd ->
            Random.int 1 1


{-| Given a int between 0 and 100 (will cap if outside of range), will return
    a room type based on the hardcoded distribution of types
-}
getRoomType : Int -> RoomType
getRoomType index =
    let
        clampedIndex =
            clamp 0 100 index
    in
        if clampedIndex < 100 then
            Rectangular
        else if clampedIndex < 50 then
            Cross
        else if clampedIndex < 60 then
            Diamond
        else if clampedIndex < 70 then
            Potion
        else if clampedIndex < 80 then
            Circular
        else if clampedIndex < 90 then
            DiagonalSquares
        else
            DeadEnd


roomTypeGenerator : Generator RoomType
roomTypeGenerator =
    Random.map getRoomType (Random.int 0 100)
