require "world_gen"
require "world_gen/render/stumpy_png/png_render"
require "../passes/debug_color"


class ExampleWorld < World
  include PNGRender
  
  def initialize(x_range, y_range, z_range)
    super x_range, y_range, z_range
  end
  
  protected def make_passes
    pass = Pass.new
    passes << pass
  end
end
