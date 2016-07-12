module Game.Collision exposing (..)

{-| This module handles all movement inputs and will move players, trigger new areas, shop screens, down stairs etc.
-}

import Dict exposing (..)
import Utils.Vector as Vector exposing (..)
import Game.Data exposing (..)
import Game.Keyboard exposing (..)
import Game.Maps as Maps exposing (..)
import Tile exposing (..)
import GameData.Building as Building exposing (..)
import Monster.Monster as Monster exposing (..)
import Shop.Shop as Shop exposing (..)
import Hero exposing (..)
import Combat exposing (..)
import Utils.IdGenerator as IdGenerator exposing (..)
import Stats exposing (..)


tryMoveHero : Direction -> Model -> Model
tryMoveHero dir ({ hero } as model) =
    let
        movedHero =
            { hero | position = Vector.add hero.position (dirToVector dir) }

        obstructions =
            queryPosition movedHero.position model
    in
        case obstructions of
            ( _, _, Just monster, _ ) ->
                attack monster model

            -- entering a building
            ( _, Just building, _, _ ) ->
                enterBuilding building model

            -- path blocked
            ( True, _, _, _ ) ->
                model

            -- path free, moved
            ( False, _, _, _ ) ->
                { model | hero = movedHero }


enterBuilding : Building -> Model -> Model
enterBuilding building ({ hero, map } as model) =
    case Building.buildingType building of
        LinkType link ->
            { model
                | map = Maps.updateArea link.area map
                , hero = { hero | position = link.pos }
            }

        ShopType shopType ->
            { model
                | currentScreen = BuildingScreen building
                , shop = Shop.setCurrentShopType shopType model.shop
            }

        Ordinary ->
            { model | currentScreen = BuildingScreen building }


{-| Given a position and a map, work out everything on the square
-}
queryPosition : Vector -> Model -> ( Bool, Maybe Building, Maybe Monster, Bool )
queryPosition pos ({ hero, map, monsters } as model) =
    let
        maybeTile =
            Dict.get (toString pos) (getMap map)

        maybeBuilding =
            buildingAtPosition pos (Maps.getBuildings map)

        maybeMonster =
            monsters
                |> List.filter (\x -> pos `Vector.equal` x.position)
                |> List.head

        isHero =
            hero.position `Vector.equal` pos

        tileObstruction =
            case maybeTile of
                Just tile ->
                    Tile.isSolid tile

                Nothing ->
                    False
    in
        ( tileObstruction, maybeBuilding, maybeMonster, isHero )


{-| Given a point and a list of buildings, return the building that the point is within or nothing
-}
buildingAtPosition : Vector -> List Building -> Maybe Building
buildingAtPosition pos buildings =
    let
        buildingsAtTile =
            List.filter (Building.isBuildingAtPosition pos) buildings
    in
        case buildingsAtTile of
            b :: rest ->
                Just b

            _ ->
                Nothing


attack : Monster -> Model -> Model
attack monster ({ hero, seed, monsters } as model) =
    let
        ( stats', seed', damage ) =
            Combat.attack hero.stats monster.stats seed

        monster' =
            { monster | stats = stats' }

        monstersWithoutMonster =
            List.filter (\x -> not (IdGenerator.equals monster.id x.id)) monsters

        monsters' =
            if Stats.isDead monster'.stats then
                monstersWithoutMonster
            else
                monster' :: monstersWithoutMonster

        newMsg =
            newHitMessage "You" (Monster.name monster) (toString damage)
    in
        { model | monsters = monsters', messages = newMsg :: model.messages }


defend : Monster -> Model -> Model
defend monster ({ hero, seed } as model) =
    let
        ( heroStats', seed', damage ) =
            Combat.attack monster.stats hero.stats seed

        hero' =
            { hero | stats = heroStats' }

        newMsg =
            newHitMessage (Monster.name monster) "you" (toString damage)
    in
        { model | hero = hero', seed = seed', messages = newMsg :: model.messages }


newHitMessage : String -> String -> String -> String
newHitMessage attacker defender damage =
    attacker ++ " hit the " ++ defender ++ " for " ++ damage ++ " damage!"



---------------------
-- Moving monsters --
---------------------


moveMonsters : List Monster -> List Monster -> Model -> Model
moveMonsters monsters movedMonsters ({ hero, map } as model) =
    case monsters of
        [] ->
            { model | monsters = movedMonsters }

        monster :: restOfMonsters ->
            let
                movedMonster =
                    pathMonster monster hero

                obstructions =
                    queryPosition movedMonster.position model

                isObstructedByMovedMonsters =
                    isMonsterObstruction movedMonster movedMonsters
            in
                case obstructions of
                    -- hit hero
                    ( _, _, _, True ) ->
                        let
                            model' =
                                defend monster model
                        in
                            moveMonsters restOfMonsters (monster :: movedMonsters) model'

                    ( True, _, _, _ ) ->
                        moveMonsters restOfMonsters (monster :: movedMonsters) model

                    ( _, Just _, _, _ ) ->
                        moveMonsters restOfMonsters (monster :: movedMonsters) model

                    ( _, _, Just _, _ ) ->
                        moveMonsters restOfMonsters (monster :: movedMonsters) model

                    _ ->
                        if isObstructedByMovedMonsters then
                            moveMonsters restOfMonsters (monster :: movedMonsters) model
                        else
                            moveMonsters restOfMonsters (movedMonster :: movedMonsters) model


pathMonster : Monster -> Hero -> Monster
pathMonster monster hero =
    let
        { x, y } =
            Vector.sub hero.position monster.position

        moveVector =
            Vector.new (x // abs x) (y // abs y)
    in
        { monster | position = Vector.add monster.position moveVector }


isMonsterObstruction : Monster -> List Monster -> Bool
isMonsterObstruction monster monsters =
    List.any (Vector.equal monster.position) (List.map .position monsters)
