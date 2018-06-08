%i(red green orange).each do |color|
  unless "test".respond_to?(color)
    eval "class String; alias_method(:#{color}, :itself) end"
  end
end
