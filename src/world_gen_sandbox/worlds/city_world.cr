require "world_gen"
require "world_gen/render/stumpy_png/png_render"
require "../passes/debug_color"


class CityWorld < World
  include PNGRender
  
  def initialize(x_range, y_range, z_range)
    super x_range, y_range, z_range
    assets.open_content("../content/city")

    @perlin_noise = PerlinNoise.new(1234)
  end
  
  protected def make_passes
    pass = Pass.new
    passes << pass

    pass.define_tile {|_, _, _, _| Tile.new("tile")}
    pass.define_block do |_, _, x, y, z|
      b = Block.new
      if z < @perlin_noise.height(x, y, 10)
        b.type = "block"
      end
      b[:color] = DebugColor.get_color(x, y, z, x_range, y_range, z_range)
      b
    end
  end
end
