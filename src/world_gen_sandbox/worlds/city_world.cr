require "perlin_noise"
require "world_gen"
require "world_gen/render/stumpy_png/png_render"
require "../passes/debug_color"


class CityWorld < World
  include PNGRender
  DIMINISH = 0.1_f32**4

  MAX_BUILDING_HEIGHT = 8

  BUILDING_HEIGHT_SEED = "building_height_seed".hash * DIMINISH
  
  CITY_BUILDING_CHANCE = 1
  CITY_BUILDING_OUTOF = 2

  BUILDING_SEED = "building_seed".hash * DIMINISH

  BUILDING_COLORS = ["6A5039FF", "F4E4CAFF", "FFFDF2FF",
                     "E0E2DBFF", "D2D4C8FF", "B8BDB5FF",
                     "889696FF", "F2C5A6FF", "E49880FF",
                     "C37E61FF", "D2D4C8FF", "9D705DFF"]
  BUILDING_COLORS_SEED = "building_colors_seed".hash * DIMINISH

  DOORS = ["door_1","door_2","door_3","door_4","door_5",]
  DOORS_SEED  = "doors_seed".hash * DIMINISH
  DOOR_ROTATION_SEED = "rotation_seed".hash * DIMINISH

  WINDOWS = ["window_1", "window_2", "window_3", "window_4"]
  WINDOWS_SEED  = "windows_seed".hash * DIMINISH

  X_ROAD_SEED = "x_road_seed".hash * DIMINISH
  Y_ROAD_SEED = "y_road_seed".hash * DIMINISH
  
  CITY_ROAD_CHANCE = 1
  CITY_ROAD_OUTOF = 2
  SUBURB_ROAD_CHANCE = 1
  SUBURB_ROAD_OUTOF = 10
  COUNTRY_ROAD_CHANCE = 1
  COUNTRY_ROAD_OUTOF = 20

  FOLIAGE = ["foliage_1", "foliage_2", "foliage_3"]
  FOLIAGE_CHANCE = 1
  FOLIAGE_OUTOF = 2
  FOLIAGE_SEED = "foliage".hash * DIMINISH

  RAINBOW_COLORS = ["ff0000ff", "ff4000ff", "ff8000ff", 
                    "ffbf00ff", "ffff00ff", "bfff00ff", 
                    "80ff00ff", "40ff00ff", "00ff00ff", 
                    "00ff80ff"].reverse

  MAX_DENSITY = 10

  def initialize(x_range, y_range, z_range)
    super x_range, y_range, z_range
    assets.open_content("../content/city")

    @perlin = PerlinNoise.new(Random.rand(Int32::MAX))
    #@perlin.step = 0.2_f32
  end

  def get_density(x, y)
    @perlin.height(x, y, MAX_DENSITY)
  end

  def get_density_color(x, y)
    RAINBOW_COLORS[get_density(x, y)]
  end

  def get_building_height(x, y)
    height = @perlin.height(x, y, MAX_BUILDING_HEIGHT)
    min_density = MAX_DENSITY / 2
    max_gap = MAX_DENSITY - min_density
    density_gap = get_density(x, y) - min_density
    mod = density_gap.to_f / max_gap.to_f
    (height * ((mod / 2.0) + 0.5)).round.to_i
  end

  def is_building_at?(x, y) : Bool
    if get_terrain_type(x, y) == "water" || get_terrain_type(x, y) == "sand" || get_terrain_type(x, y) == "grass" || is_road?(x, y)
      false
    elsif get_terrain_type(x, y) == "cement"
      @perlin.bool(x, y, CITY_BUILDING_CHANCE, CITY_BUILDING_OUTOF, BUILDING_SEED)
    else
      false
    end    
  end

  def is_building?(x, y, z) : Bool
    is_building_at?(x, y) && z < get_building_height(x, y)
  end

  def get_window(x, y)
    @perlin.item(x, y, WINDOWS, WINDOWS_SEED)    
  end

  def get_door(x, y)
    door = Block.new(@perlin.item(x, y, DOORS, DOORS_SEED))
    door[:rotation] = @perlin.item(x, y, ROTATIONS.keys, DOOR_ROTATION_SEED)
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

  def is_road?(x, y)
    is_road_x?(x, y) || is_road_y?(x, y) 
  end

  def is_road_x?(x, y)
    if x.even? || get_terrain_type(x, y) == "water" || get_terrain_type(x, y) == "sand" 
      false
    else
      if get_density(x, y) > 6 
        @perlin.bool(x, CITY_ROAD_CHANCE, CITY_ROAD_OUTOF, X_ROAD_SEED)
      elsif get_density(x, y) > 4 
        @perlin.bool(x, SUBURB_ROAD_CHANCE, SUBURB_ROAD_OUTOF, X_ROAD_SEED)
      else
        @perlin.bool(x, COUNTRY_ROAD_CHANCE, COUNTRY_ROAD_OUTOF, X_ROAD_SEED)
      end
    end
  end

  def is_road_y?(x, y)
    if y.odd? || get_terrain_type(x, y) == "water" || get_terrain_type(x, y) == "sand" 
      false
    else
      if get_density(x, y) > 6 
        @perlin.bool(y, CITY_ROAD_CHANCE, CITY_ROAD_OUTOF, Y_ROAD_SEED)
      elsif get_density(x, y) > 4 
        @perlin.bool(y, SUBURB_ROAD_CHANCE, SUBURB_ROAD_OUTOF, Y_ROAD_SEED)
      else
        @perlin.bool(y, COUNTRY_ROAD_CHANCE, COUNTRY_ROAD_OUTOF, Y_ROAD_SEED)
      end
    end 
  end

  def is_road_4way?(x, y)
    is_road_x?(x, y) && is_road_y?(x, y) 
  end

  def get_terrain_type(x, y)
    if get_density(x, y) > 4
      "cement"
    elsif get_density(x, y) > 1
      "grass"
    elsif get_density(x, y) == 1
      "sand"  
    else
      "water"
    end
  end

  def get_terrain_color(x, y)
    case get_terrain_type(x, y)
      when "cement"
        "AAAAAAFF"
      when "grass"
        "80FF00FF"
      when "sand"
        "FFCC66FF"
      when "water"
        "0000FFFF"
    end
  end

  def is_foliage?(x, y, z)
    z == 0 && get_terrain_type(x, y) == "grass" && @perlin.bool(x, y, FOLIAGE_CHANCE, FOLIAGE_OUTOF, FOLIAGE_SEED) && !is_road?(x, y)
  end

  def get_foliage(x, y)
    @perlin.item(x, y, FOLIAGE, FOLIAGE_SEED)
  end
  
  protected def make_passes
    pass = Pass.new
    passes << pass

    pass.define_tile do |_, _, x, y| 
      t = Tile.new("tile")
      if is_road?(x, y)
        if is_road_4way?(x, y)
          t.type = "road_4_way"
          t[:rotation] = "deg_0"
        else
          t.type = "road_straight"
          if is_road_x?(x, y)
            t[:rotation] = "deg_0"
          elsif is_road_y?(x, y)
            t[:rotation] = "deg_90"
          end
        end
      else
        t[:color] = get_terrain_color(x, y)
      end
      t
    end

    pass.define_block do |_, blocks, x, y, z|
      b = Block.new
      if is_building?(x, y, z)
        b.type = "block"
      elsif is_foliage?(x, y, z)
        b.type = get_foliage(x, y)
        blocks << b
      end
      if b.type == "block"
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
