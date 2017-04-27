module DebugColor
  def self.get_color(x, y, z, x_range : Range(Int32, Int32), y_range : Range(Int32, Int32), z_range : Range(Int32, Int32))
    r_s = (UInt8::MAX * (x.to_f/x_range.size)).to_u8.to_s(16)
    g_s = (UInt8::MAX * (y.to_f/y_range.size)).to_u8.to_s(16)
    b_s = (UInt8::MAX * (z.to_f/z_range.size)).to_u8.to_s(16)
    a_s = (UInt8::MAX).to_s(16)

    if r_s.size == 1
      r_s = r_s.insert(0, "0") 
    end

    if g_s.size == 1
      g_s = g_s.insert(0, "0") 
    end

    if b_s.size == 1
      b_s = b_s.insert(0, "0") 
    end

    if a_s.size == 1
      a_s = a_s.insert(0, "0") 
    end
    "#{r_s}#{g_s}#{b_s}#{a_s}"
  end
end