import vmath

type
  TileKind* = enum
    empty
    wall
    floor
    controlPoint # For area control game modes, last team changes the colour of the tile

  Tile* = object
    occupied*: bool
    case kind*: TileKind
    of controlPoint:
      teamId*: int
    else:
      discard

  World* = object
    size*: IVec2
    data*: seq[Tile]

const walkable = {floor, controlPoint}

proc canMoveTo*(tile: Tile): bool = tile.kind in walkable and not tile.occupied

