crystal:
  clazz =
    [:a, :b, :c].map do |c|
      c.to_s * 2
    end.join(" ")
p class=clazz
