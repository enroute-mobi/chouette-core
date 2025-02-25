collection @collection

node do |object|
  label_method = begin
    if locals[:label_method].is_a?(Symbol)
      Proc.new { |o| o.send(locals[:label_method]) }
    elsif locals[:label_method].is_a?(Proc)
      locals[:label_method]
    end
  end

  {
    id: object.id,
    text: label_method.call(object)
  }
end