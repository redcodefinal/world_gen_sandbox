require "perlin_noise"
require "world_gen"
require "world_gen/render/stumpy_png/png_render"
require "../passes/debug_color"

class RotationTestWorld < World
  include PNGRender

  property blocks : Array(Block)

  def initialize(@blocks = [] of Block)
    super (0..4), (0..4), (0..0)
  end

  private def get_rotation(x, y)
    if x == 1 && y == 1
      "deg_0"
    elsif x == 1 && y == 3
      "deg_90"
    elsif x == 3 && y == 3
      "deg_180"
    elsif x == 3 && y == 1
      "deg_270"
    end
  end

  private def get_color(x, y)
    if x == 1 && y == 1
      "FFFFFFFF"
    elsif x == 1 && y == 3
      "FF0000FF"
    elsif x == 3 && y == 3
      "00FF00FF"
    elsif x == 3 && y == 1
      "0000FFFF"
    end
  end
  
  protected def make_passes
    pass = Pass.new
    passes << pass

    pass.define_tile do |_, _, x, y|
      tile = Tile.new
      tile.type = "tile"
      if x == 0 && y == 0
        tile[:color] = get_color(x, y)
      end
      tile
    end

    blocks.each do |block|
      pass.define_block do |last_blocks, blocks, x, y, z|
        unless [1,3].includes?(x) && [1,3].includes?(y)
          new_block = Block.new
        else
          new_block = block.clone.as(Block)          
          if new_block[:rotation]? && get_rotation(x, y)
            nb_rotation = new_block[:rotation].to_s.split('_')[1].to_i32
            g_rotation = get_rotation(x,y).to_s.split('_')[1].to_i32
            rotation = (g_rotation + nb_rotation) % 360
            new_block[:rotation] = "deg_#{rotation}"
          elsif get_rotation(x, y)
            new_block[:rotation] = get_rotation(x, y) 
          end
          
          new_block[:color] = get_color(x, y)
          new_block
        end
      end
    end
  end
end