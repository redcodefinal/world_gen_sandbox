require "perlin_noise"
require "world_gen"
require "world_gen/render/stumpy_png/png_render"
require "../passes/debug_color"


class CityWorld < World
  include PNGRender
  DIMINISH = 0.1_f32**4

  MAX_BUILDING_HEIGHT = 8

  BUILDING_HEIGHT_SEED = make_seed
  
  CITY_BUILDING_CHANCE = 2
  CITY_BUILDING_OUTOF = 3

  BUILDING_SEED = make_seed

  BUILDING_COLORS = ["6A5039FF", "F4E4CAFF", "FFFDF2FF",
                     "E0E2DBFF", "D2D4C8FF", "B8BDB5FF",
                     "889696FF", "F2C5A6FF", "E49880FF",
                     "C37E61FF", "D2D4C8FF", "9D705DFF"]
  BUILDING_COLORS_SEED = make_seed

  DOORS = ["door_1","door_2","door_3","door_4","door_5",]
  DOORS_SEED  = make_seed
  DOOR_ROTATION_SEED = make_seed

  WINDOWS = ["window_1", "window_2", "window_3", "window_4"]
  WINDOWS_SEED  = make_seed

  X_ROAD_SEED = "x_road_seed".hash * DIMINISH
  Y_ROAD_SEED = "y_road_seed".hash * DIMINISH
  
  CITY_ROAD_CHANCE = 4
  CITY_ROAD_OUTOF = 7
  SUBURB_ROAD_CHANCE = 1
  SUBURB_ROAD_OUTOF = 100
  BRIDGE_ROAD_CHANCE = 1
  BRIDGE_ROAD_OUTOF = 150

  SMALL_HOUSES = ["small_house_1", "small_house_2"]
  SMALL_HOUSE_SEED = make_seed
  SMALL_HOUSE_TYPE_SEED = make_seed
  SMALL_HOUSE_ROTATION_SEED = make_seed
  
  FOLIAGE = ["foliage_1", "foliage_2", "foliage_3"]
  FOLIAGE_CHANCE = 1
  FOLIAGE_OUTOF = 2
  FOLIAGE_SEED = make_seed

  RAINBOW_COLORS = ["ff0000ff", "ff4000ff", "ff8000ff", 
                    "ffbf00ff", "ffff00ff", "bfff00ff", 
                    "80ff00ff", "40ff00ff", "00ff00ff", 
                    "00ff80ff"].reverse

  CEMENT_LEVEL = 0.6
  GRASS_LEVEL = 0.27
  WATER_LEVEL = 0.25

  UMBRELLA_SEED = make_seed
  UMBRELLA_FLIP_SEED = make_seed
  UMBRELLA_LEVEL = 0.26
  UMBRELLA_CHANCE = 1
  UMBRELLA_OUTOF = 50

  BOAT_LEVEL = 0.1
  BOAT_SEED = make_seed
  BOAT_CHANCE = 1
  BOAT_OUTOF = 400

  DOCK_LEVEL_END = 0.2
  DOCK_X_SEED = make_seed
  DOCK_Y_SEED = make_seed
  DOCK_CHANCE = 1
  DOCK_OUTOF = 50

  def initialize(x_range, y_range, z_range)
    super x_range, y_range, z_range
    assets.open_content("../content/city")

    @perlin = PerlinNoise.new(Random.rand(Int32::MAX))
    @perlin.step = 0.05_f32
  end

  def self.make_seed : Float32
    # PRODUCES A RANDOM STRING AND HASHES IT
    letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890"
    letters += letters
    letters = letters.chars.shuffle.join
    letters.hash * DIMINISH
  end

  def get_density(x, y)
    n = ((@perlin.noise(x ,y) + 1.0) / 2.0)
    if n > 1.0
      n = 1.0 - (n - 1.0)
    end
    n
  end

  def get_density_color(x, y)
    RAINBOW_COLORS[(get_density(x, y)*RAINBOW_COLORS.size).to_i]
  end

  def get_terrain_type(x, y)
    if get_density(x, y) > CEMENT_LEVEL
      "cement"
    elsif get_density(x, y) > GRASS_LEVEL
      "grass"
    elsif get_density(x, y) > WATER_LEVEL
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

  def get_building_height(x, y)
    height = @perlin.height(x, y, MAX_BUILDING_HEIGHT)
    min_density = 0.5
    max_gap = 0.5
    density_gap = get_density(x, y) - min_density
    mod = density_gap / max_gap
    (height * ((mod / 2.0) + max_gap)).round.to_i
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
    if x.even? || get_terrain_type(x, y) == "water"
      false
    else
      int = @perlin.int(x, 0, BRIDGE_ROAD_OUTOF, X_ROAD_SEED)
      if get_terrain_type(x, y) == "cement" && (int % CITY_ROAD_OUTOF) <= CITY_ROAD_CHANCE
        true
      elsif get_terrain_type(x, y) == "grass" && (int % SUBURB_ROAD_OUTOF) <= SUBURB_ROAD_CHANCE
        true
      elsif int <= BRIDGE_ROAD_CHANCE
        true
      else
        false
      end
    end
  end

  def is_road_y?(x, y)
    if y.odd? || get_terrain_type(x, y) == "water"
      false
    else
      int = @perlin.int(y, 0, BRIDGE_ROAD_OUTOF, Y_ROAD_SEED)
      if get_terrain_type(x, y) == "cement" && (int % CITY_ROAD_OUTOF) <= CITY_ROAD_CHANCE
        true
      elsif get_terrain_type(x, y) == "grass" && (int % SUBURB_ROAD_OUTOF) <= SUBURB_ROAD_CHANCE
        true
      elsif int <= BRIDGE_ROAD_CHANCE
        true
      else
        false
      end
    end 
  end

  def is_road_4way?(x, y)
    is_road_x?(x, y) && is_road_y?(x, y)
  end

  def is_foliage?(x, y, z)
    z == 0 && get_terrain_type(x, y) == "grass" && @perlin.bool(x, y, FOLIAGE_CHANCE, FOLIAGE_OUTOF, FOLIAGE_SEED) && !is_road?(x, y)
  end

  def get_foliage(x, y)
    @perlin.item(x, y, FOLIAGE, FOLIAGE_SEED)
  end

  def is_small_house?(x, y, z)
    z == 0 && get_terrain_type(x, y) == "grass" && 
    @perlin.bool(x, y, 1, 2, SMALL_HOUSE_SEED) && 
    !is_road?(x, y) &&
    @perlin.height(x + SMALL_HOUSE_SEED.to_i, y + SMALL_HOUSE_SEED.to_i, 100) > 50
  end

  def get_small_house_type(x, y)
    @perlin.item(x, y, SMALL_HOUSES, SMALL_HOUSE_TYPE_SEED )
  end

  def get_small_house_rotation(x, y)
    @perlin.item(x, y, ROTATIONS.keys, SMALL_HOUSE_ROTATION_SEED)
  end

  def get_building_color(x, y)
    @perlin.item(x, y, BUILDING_COLORS, BUILDING_COLORS_SEED)
  end

  def is_umbrella?(x, y, z)
    z == 0 && get_terrain_type(x, y) == "sand" && get_density(x, y) < UMBRELLA_LEVEL && @perlin.bool(x ,y, UMBRELLA_CHANCE, UMBRELLA_OUTOF, UMBRELLA_SEED) && !is_road?(x ,y)
  end

  def get_umbrella_flip_h?(x, y)
    (@perlin.bool(x, y, 1, 2, UMBRELLA_FLIP_SEED) ? "true" : "false")
  end

  def is_boat?(x, y, z)
    z == 0 && get_density(x, y) < BOAT_LEVEL && @perlin.bool(x ,y, BOAT_CHANCE, BOAT_OUTOF, BOAT_SEED) && !is_road?(x ,y)
  end

  def is_dock_x?(x, y, z)
    if get_terrain_type(x, y) != "water"
      false
    else
      z == 0 &&
      x.even? &&
      get_density(x, y) < WATER_LEVEL && 
      get_density(x, y) > DOCK_LEVEL_END &&
      @perlin.bool(x, DOCK_CHANCE, DOCK_OUTOF, DOCK_X_SEED)
    end
  end

  def is_dock_y?(x, y, z)
    if get_terrain_type(x, y) != "water"
      false
    else
      z == 0 &&
      y.odd? &&
      get_density(x, y) < WATER_LEVEL && 
      get_density(x, y) > DOCK_LEVEL_END &&
      @perlin.bool(x, DOCK_CHANCE, DOCK_OUTOF, DOCK_X_SEED)
    end
  end

  def is_dock?(x, y, z)
    is_dock_x?(x, y, z) || is_dock_y?(x, y, z)
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
        # TODO: WRITE 3-WAY!  
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
        b[:color] = get_building_color(x, y)
        blocks << b
        get_features(x, y, z).each do |feature|
          blocks << feature
        end
      elsif is_foliage?(x, y, z)
        b.type = get_foliage(x, y)
        blocks << b
      elsif is_small_house?(x, y, z)
        b.type = get_small_house_type(x, y)
        b[:color] = get_building_color(x, y)
        b[:rotation] = get_small_house_rotation(x, y)
        blocks << b        
      elsif is_umbrella?(x, y, z)
        b.type = "umbrella"
        b[:flip_h] = get_umbrella_flip_h?(x, y)
        blocks << b
      elsif is_boat?(x, y, z)
        b.type = "boat"
        blocks << b
      #elsif is_dock?(x, y, z)
      #  b.type = "dock"
      #  blocks << b  
      end
      Block.new
    end
  end
end
