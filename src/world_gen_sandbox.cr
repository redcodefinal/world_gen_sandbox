require "./world_gen_sandbox/**"
require "benchmark"

# num = 0
# while num < 4
#   cw.draw_world "./shots/city/city#{num}.png"
#   cw.rotate_counter_clockwise
#   num += 1
# end
Benchmark.bm do |x|
  x.report("CityWorld") do
    cw = CityWorld.new((0..ARGV[0].to_i), (0..ARGV[0].to_i), (0..10))
    cw.draw_world "./shots/city/city.png"
  end
end