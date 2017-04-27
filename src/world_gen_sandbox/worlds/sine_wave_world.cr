require "world_gen"
require "world_gen/render/stumpy_png/png_render"

require "../passes/sine_wave"
require "../passes/debug_color"


class SineWaveWorld < World
  include PNGRender

  def initialize(x_range, y_range, z_range)
    super x_range, y_range, z_range
  end
  
  protected def make_passes
    pass = Pass.new
    passes << pass

    pass.define_block do |_, _, x, y, z|
      block = Block.new
      block.type = SineWave.get_type(x, y, z, x_range, y_range, z_range)
      block[:color] = DebugColor.get_color(x, y, z, x_range, y_range, z_range)
      block
    end
  end
end
