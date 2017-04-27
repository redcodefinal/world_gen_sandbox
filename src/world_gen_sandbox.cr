require "./world_gen_sandbox/**"

cw = CityWorld.new((0..40), (0..40), (0..40))
num = 0
while num < 4
  cw.draw_world "./shots/city/city#{num}.png"
  cw.rotate_counter_clockwise
  num += 1
end