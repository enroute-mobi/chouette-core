module ConnectionLinksHelper
  def connection_link_duration_select f, duration
    content_tag(:div, class: 'col-md-6') do
      selected = f.object.send(duration).presence
      collection = selected ? (0..selected+10) : (0..15)
      collection = collection.map { |x| [x,x*60]  }.to_h

      f.input duration, as: :integer, min: 0, wrapper: :horizontal_shrinked_input, input_html: { value: selected }
    end
  end

  def connection_link_type_options
    Chouette::ConnectionLink.connection_link_types.map do |link_type|
      [ t(link_type, scope: 'activerecord.attributes.connection_link'), link_type ]
    end
  end
end
