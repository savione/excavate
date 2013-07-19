--- @author Cutter Coryell
-------------------------------------------------------------------------------
--| Minecraft Turtle routine to excavate a section of earth, storing everything
--| it finds in chests. Optionally it can exclude storing certain items, store
--| only certain items, or store nothing at all.


-------------------------------------------------------------------------------
------------------------------- HELPER FUNCTIONS ------------------------------
-------------------------------------------------------------------------------

---- Informational Messages ----

--- Print the usage message for this program.
local usage = function ()
  print("\n  usage: " .. arg[0] .. " shape depth dimension "
          .. "[second_dimension] [-e [slots to exclude]] "
          .. " [-i [slots to include]] [-h]\n")
end


--- Print the help message for this program.
local help = function ()
  print("\nNAME\n\n  " .. arg[0] .. "\n")
  print("SYNOPSIS"); usage()
  print(
[[
DESCRIPTION

  Minecraft Turtle routine to excavate a section of earth, storing everything
  it finds in chests. Optionally it can exclude storing certain items, store
  only certain items, or store nothing at all.

ARGUMENTS

  shape - The shape the Turtle is to excavate.

    range:  cyl     -   cylinder    (1 dimension)
            halfcyl   -   half-cylinder (1 dimension)
            rect    -   rectangle   (1 or 2 dimension)
            righttri  -   right triangle  (1 or 2 dimension)

  depth - The depth in meters the Turtle is to excavate.

    range:  integer 1:*

  dimension - The linear dimension of the shape to be excavated in
          meters. For the cylinder and half-cylinder, it is the
          diameter. For the rectangle and right triangle, it is the x
          side-length. If second_dimension is not provided, it is
          also the z side-length.

    range:  integer 1:*

OPTIONAL ARGUMENTS

  second_dimension  - The secondary linear dimension in meters of the
              shape to be excavated. Can only be included if
              shape is rect or righttri. For rect and righttri
              it is the z side-length.

    range:  integer 1:*

OPTIONS

  -e  - Exclude the resources in the specified slots while collecting and
      collect everything else. If no slot numbers are provided, will
      exlude nothing. -e with no slot numbers is default behavior.
      Mutually exclusive with -i.

    OPTIONAL ARGUMENTS

      slots to exclude  - A series of numbers specifying slots that
                          contain samples of the resource to be excluded.

        range: any number of integers 1:16; duplicates have no effect

  -i  - Include the resources in the specified slots while collecting and
      exclude everything else. If no slot numbers are provided, will
      include nothing.

    OPTIONAL ARGUMENTS

      slots to exclude  - A series of numbers specifying slots that
                         contain samples of the resource to be excluded.

        range: any number of 1:16; duplicates have no effect

  -h  - Display this help text. All other arguments will be ignored.

NOTES

The Turtle must be set with initial coordinates (0, 0) and must be facing
North. The excavation plot will be the rectangle from (0, 0) to
(dimension, dimension) (or (dimension, second_dimension) if second_dimension
is specified).

If any collection is set to occur, then double chests must be placed at
coordinates (-1, 0), (-1, 3), (-1, 6), ..., for as many chests as the Turtle
ends up needing. In other words, they must line the x-axis of the plot.
If the Turtle cannot find an empty chest on this axis, it will panic.

]])
end


---- Shape Generators ----


--- Returns a table with x-coordinates as keys, and tables of the form
--  {z1, z2} as values, corresponding to the range of z-coordinates for any
--  given x-coordinate that belong to the given shape.
--  @param shape The shape of the excavation.
--  @param dimension The linear dimension of the shape.
--  @param second_dimension The secondary dimension of the shape (optional).
local generate_shape = function (shape, dimension, second_dimension)
  if shape == "cyl" then
    return generate_cyl(dimension)
  elseif shape == "halfcyl" then
    return generate_halfcyl(dimension)
  elseif shape == "rect" then
    return generate_rect(dimension, second_dimension)
  elseif shape == "righttri" then
    return generate_righttri(dimension, second_dimension)
  else
    error("invalid shape: " .. shape)
  end
end


--- Returns a table with x-coordinates as keys, and tables of the form
--  {z1, z2} as values, corresponding to the range of z-coordinates for any
--  given x-coordinate a cylinder of the given dimensions.
--  @param dimension The diameter of the cylinder.
local generate_cyl = function (dimension)
  local shape_tab = {}
  local rad = dimension / 2
  for x = 0, rad do
    local z1 = math.floor(0.5 + rad - math.sqrt(x * (dimension - x)))
    local z2 = dimension - z1
    shape_tab[x] = {z1, z2}
    shape_tab[dimension - 1 - x] = {z1, z2}
  end
  return shape_tab
end
-- Test code
--[[
cyl = generate_cyl(100)
for x = 0, #cyl do
  print("{"..x..","..cyl[x][1].."}, {"..x..","..cyl[x][2].."},")
end
--]]


--- Returns a table with x-coordinates as keys, and tables of the form
--  {z1, z2} as values, corresponding to the range of z-coordinates for any
--  given x-coordinate a half-cylinder of the given dimensions.
--  @param dimension The diameter of the half-cylinder.
local generate_halfcyl = function (dimension)
  local shape_tab = {}
  local rad = dimension / 2
  for x = 0, rad do
    local z1 = math.floor(0.5 + rad - math.sqrt(x * (dimension - x)))
    shape_tab[x] = {z1, rad}
    shape_tab[dimension - 1 - x] = {z1, rad}
  end
  return shape_tab
end
-- Test code
--[[
halfcyl = generate_halfcyl(101)
for x = 0, #halfcyl do
  print("{"..x..","..halfcyl[x][1].."}, {"..x..","..halfcyl[x][2].."},")
end
--]]


--- Returns a table with x-coordinates as keys, and tables of the form
--  {z1, z2} as values, corresponding to the range of z-coordinates for any
--  given x-coordinate a rectangle of the given dimensions.
--  @param dimension The x side-length of the rectangle.
--  @param second_dimension If provided, the z side-length of the rectangle.
--                          Otherwise it will be a square.
local generate_rect = function (dimension, second_dimension)
  local shape_tab = {}
  if not second_dimension then
    second_dimension = dimension
  end
  local z2 = second_dimension - 1
  for x = 0, dimension - 1 do
    shape_tab[x] = {0, z2}
  end
  return shape_tab
end
-- Test code
--[[
rect = generate_rect(100, 50)
for x = 0, #rect do
  print("{"..x..","..rect[x][1].."}, {"..x..","..rect[x][2].."},")
end
--]]


--- Returns a table with x-coordinates as keys, and tables of the form
--  {z1, z2} as values, corresponding to the range of z-coordinates for any
--  given x-coordinate a right-triangle of the given dimensions.
--  @param dimension The x side-length of the right-triangle.
--  @param second_dimension If provided, the z side-length of the triangle.
--                          Otherwise it will be an isosceles right-triangle.
local generate_righttri = function (dimension, second_dimension)
  local shape_tab = {}
  if not second_dimension then
    second_dimension = dimension
  end
  for x = 0, dimension - 1 do
    local z2 = math.floor(0.5 + (second_dimension  - 1 )
                                  * (1 - x / (dimension - 1)))
    shape_tab[x] = {0, z2}
  end
  return shape_tab
end
-- Test code
--[[
righttri = generate_righttri(5)
for x = 0, #righttri do
  print("{"..x..","..righttri[x][1].."}, {"..x..","..righttri[x][2].."},")
end
--]]


---- Movement ----

--- Moves Turtle to the given x-coordinate. If there is a block in the way, he
--  will destroy it. If there is a mob in the way, he will kill it.
--  @param x The x-coordinate to move to.
local force_move_x = function (x)
  local sign
  if x_COORD < x then
    sign = '+'
  else
    sign = '-'
  end

  while x_COORD ~= x do
    if DETECT_x(sign) then
      DIG_x(sign)
      if DETECT_x(sign) then
        -- hit something solid
        return
      end
    end
    MOVE_ONE_x(sign, "attacking")
  end
end


--- Moves Turtle to the given y-coordinate. If there is a block in the way, he
--  will destroy it. If there is a mob in the way, he will kill it.
--  @param y The y-coordinate to move to.
local force_move_y = function (y)
  local sign
  if y_COORD < y then
    sign = '+'
  else
    sign = '-'
  end

  while y_COORD ~= y do
    if DETECT_y(sign) then
      DIG_y(sign)
      if DETECT_y(sign) then
        -- hit something solid
        return
      end
    end
    MOVE_ONE_y(sign, "attacking")
  end
end


--- Moves Turtle to the given z-coordinate. If there is a block in the way, he
--  will destroy it. If there is a mob in the way, he will kill it.
--  @param z The z-coordinate to move to.
local force_move_z = function (z)
  local sign
  if z_COORD < z then
    sign = '+'
  else
    sign = '-'
  end

  while z_COORD ~= z do
    if DETECT_z(sign) then
      DIG_z(sign)
      if DETECT_z(sign) then
        -- hit something solid
        return
      end
    end
    MOVE_ONE_z(sign, "attacking")
  end
end





-------------------------------------------------------------------------------
--------------------------------- MAIN DRIVER ---------------------------------
-------------------------------------------------------------------------------


---- Parse arguments ----

-- Check for -h flag and print help text if present.

for i = 1, #arg do
  if arg[i] == '-h' then
    help(arg[0])
    return
  end
end

-- Initialize shape, depth, and dimension

local shape, depth, dimension = unpack(arg, 1, 3)

local SHAPES = {cyl = true, halfcyl = true, rect = true, righttri = true}

if not SHAPES[shape] then
  print("\ninvalid shape: " .. shape)
  print("valid range: cyl halfcyl rect righttri\n")
  usage(arg[0])
  return
end

-- Check that depth and dimension are positive integers, and convert them
-- to numbers

if depth then
  depth = tonumber(depth)
  if not depth then
    usage(arg[0])
    return
  elseif math.floor(depth) ~= depth or depth < 1 then
    print("\ninvalid depth: " .. depth)
    print("valid range: integer 1:*\n")
    usage(arg[0])
    return
  end
else
  usage(arg[0])
  return
end

if dimension then
  dimension = tonumber(dimension)
  if not dimension then
    usage(arg[0])
    return
  elseif math.floor(dimension) ~= dimension or dimension < 1 then
    print("\ninvalid dimension: " .. dimension)
    print("valid range: integer 1:*\n")
    usage(arg[0])
    return
  end
else
  usage(arg[0])
  return
end

-- If applicable, initialize second_dimension and option (the -e/-i flag),
-- collect and any provided slot numbers.

local second_dimension
local option
local slots = {}

if arg[4] == "-e" or arg[4] == "-i" then
  option = arg[4]
  slots = {unpack(arg, 5)}
elseif arg[4] then
  if shape == "rect" or shape == "righttri" then
    second_dimension = arg[4]
    option = arg[5]
    slots = {unpack(arg, 6)}
  else
    print("error: " .. shape
        .. " does not have an applicable second_dimension\n")
    usage(arg[0])
    return
  end
end

-- Check that if second_dimension is provided, then it is a positive integer,
-- and convert it to a number

if second_dimension then
  second_dimension = tonumber(second_dimension)
  if not second_dimension then
    usage(arg[0])
    return
  elseif math.floor(second_dimension) ~= second_dimension
                           or second_dimension < 1 then
    usage(arg[0])
    print("\ninvalid second_dimension: " .. second_dimension)
    print("valid range: integer 1:*\n")
    return
  end
end

-- Check that option is -e or -i, if it exists

if option and not (option == '-e' or option == '-i') then
  print("\ninvalid option: " .. option)
  print("valid range: -e -i -h\n")
  usage(arg[0])
  return
end

-- Check that all the provided slots are integers in [1, 16] and convert them
-- to numbers

for n=1, #slots do
  local slot = tonumber(slots[n])
  if not slot or math.floor(slot) ~= slot or slot < 1 or 16 < slot then
    print("\ninvalid slot number: " .. slot)
    print("valid range: integer 1:16\n")
    usage(arg[0])
    return
  end
  slots[n] = slot
end

print(shape, depth, dimension, second_dimension, option, unpack(slots))


--- @copyright 2013 Cutter Coryell