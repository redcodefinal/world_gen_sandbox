#TODO: Add parameters for phase and length

module SineWave
  TWO_PI = 2 * 3.141592
  
  def self.get_height(n : Int32, n_range : Range(Int32, Int32), max_height : Int32) 
    # Still dont know why 4.0 and 2.0 work right here?
    Math.sin(TWO_PI * (n - n_range.begin)/n_range.size * 4.0) * max_height/2.0 + max_height/2.0
  end

  def self.get_type(x, y, z, x_range : Range(Int32, Int32), y_range : Range(Int32, Int32), z_range : Range(Int32, Int32), axis : Symbol = :xy)
    height = 0
    if axis == :x
      height = get_height(x, x_range, z_range.size)
    elsif axis == :y
      height = get_height(y, y_range, z_range.size)      
    elsif axis == :xy
      x_height = get_height(x, x_range, z_range.size)
      y_height = get_height(y, y_range, z_range.size)

      max = [x_height, y_height].max
      min = [x_height, y_height].min

      height = ((max - min)/2.0 + min).to_i32
    end

    if z < height
      "block"
    else
      nil
    end
  end
end