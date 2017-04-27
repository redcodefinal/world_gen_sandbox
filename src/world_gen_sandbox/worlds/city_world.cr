require "perlin_noise"
require "world_gen"
require "world_gen/render/stumpy_png/png_render"
require "../passes/debug_color"


class CityWorld < World
  include PNGRender

  DIMINISH = 1.0_f32**5
  ROTATION_SEED = "rotation_seed".hash * DIMINISH
  

  MAX_BUILDING_HEIGHT = 7
  BUILDING_HEIGHT_SEED = "building_height_seed".hash * DIMINISH
  BUILDING_CHANCE = 4
  BUILDING_SEED = "building_seed".hash * DIMINISH

  BUILDING_COLORS = ["6A5039FF", "F4E4CAFF", "FFFDF2FF",
                     "E0E2DBFF", "D2D4C8FF", "B8BDB5FF",
                     "889696FF", "F2C5A6FF", "E49880FF",
                     "C37E61FF", "D2D4C8FF", "9D705DFF"]
  BUILDING_COLORS_SEED = "building_colors_seed".hash * DIMINISH

  DOORS = ["door_1","door_2","door_3","door_4","door_5",]
  DOORS_SEED  = "doors_seed".hash * DIMINISH

  WINDOWS = ["window_1", "window_2", "window_3", "window_4"]
  WINDOWS_SEED  = "windows_seed".hash * DIMINISH

  ROAD_SEED = "road_seed".hash * DIMINISH

  ROAD_CHANCE = 10

  def initialize(x_range, y_range, z_range)
    super x_range, y_range, z_range
    assets.open_content("../content/city")

    @perlin = PerlinNoise.new(Random.rand(Int32::MAX))
  end

  def is_building_at?(x, y) : Bool
    @perlin.bool(x, y, 1, BUILDING_CHANCE, BUILDING_SEED) && !is_road?(x) && !is_road?(y)
  end

  def is_building?(x, y, z) : Bool
    is_building_at?(x, y) && z < @perlin.height(x, y, MAX_BUILDING_HEIGHT, BUILDING_HEIGHT_SEED)
  end

  def get_window(x, y)
    @perlin.item(x, y, WINDOWS, WINDOWS_SEED)    
  end

  def get_door(x, y)
    door = Block.new(@perlin.item(x, y, DOORS, DOORS_SEED))
    door[:rotation] = @perlin.item(x, y, ROTATIONS.keys, ROTATION_SEED)
    door
  end

  def get_features(x, y, z) : Array(Block)
    blocks = [] of Block
    if is_building?(x, y, z)
      window_type = get_window(x, y)
      door = get_door(x, y)

      ROTATIONS.keys.each do |deg|
        if z == 0 && door[:rotation] == deg
          blocks << door
        else
          window = Block.new(window_type)
          window[:rotation] = deg
          blocks << window
        end
      end
    end
    blocks
  end

  def is_road?(x)
    @perlin.bool(x, 1, ROAD_CHANCE, ROAD_SEED)
  end

  def is_road_4way?(x, y)
    is_road?(x) && is_road?(y) 
  end
  
  protected def make_passes
    pass = Pass.new
    passes << pass

    pass.define_tile do |_, _, x, y| 
      t = Tile.new("tile")
      if is_road?(x) || is_road?(y)
        if is_road_4way?(x, y)
          t.type = "road_4_way"
          t[:rotation] = "deg_0"
        else
          t.type = "road_straight"
          if is_road?(x)
            t[:rotation] = "deg_0"
          elsif is_road?(y)
            t[:rotation] = "deg_90"
          end
        end
      end
      t
    end
    pass.define_block do |_, blocks, x, y, z|
      b = Block.new
      if is_building?(x, y, z)
        b.type = "block"
      end
      if b.type
        b[:color] = @perlin.item(x, y, BUILDING_COLORS, BUILDING_COLORS_SEED)
        blocks << b
        get_features(x, y, z).each do |feature|
          blocks << feature
        end
      end  
      Block.new
    end
  end
end
