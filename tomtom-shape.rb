# http://chouette-core.test/referentials/15823/lines/28/routes/411

url = ARGV.first

# /referentials/15823/lines/28/routes/411

format = %r{/referentials/(\d+)/lines/\d+/routes/(\d+)}

unless format =~ url
  return
end

referential_id = $1.to_i
route_id = $2.to_i

Referential.find(referential_id).switch

route = Chouette::Route.find route_id

waypoints = route.stop_areas.pluck(:latitude, :longitude)

tomtom_points = waypoints.map { |latitude, longitude| "#{latitude},#{longitude}" }.join(":")
tomtom_key = ENV["TOMTOM_API_KEY"]

tomtom_url = "https://api.tomtom.com/routing/1/calculateRoute/#{tomtom_points}/json?routeType=fastest&traffic=false&travelMode=bus&key=#{tomtom_key}"

raw_response = nil

response_time = Benchmark.realtime do
  raw_response = open(tomtom_url).read
end

File.write("tomtom.json", raw_response)

response = JSON.parse(raw_response)

tomtom_route = response["routes"].first

points = []

tomtom_route["legs"].each do |leg|
  leg["points"].map do |point|
    points << [ point["latitude"], point["longitude"] ]
  end
end

kml_template = <<~ERB
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://earth.google.com/kml/2.2">
  <Document>
    <name>Shape of <%= route.line.name %> <%= route.name %></name>

    <Style id="stoparea">
      <IconStyle>
        <Icon>
          <href>//maps.google.com/mapfiles/ms/icons/blue-dot.png</href>
        </Icon>
      </IconStyle>
    </Style>
    <Style id="shape">
      <LineStyle>
        <color>ffd18802</color>
        <width>3</width>
      </LineStyle>
    </Style>
    <Placemark>
      <name><%= route.line.name %> <%= route.name %></name>
      <description><![CDATA[Geometry points: <%= points.size %> - Tomtom response time: <%= response_time %>s ]]></description>
      <styleUrl>#shape</styleUrl>
      <LineString>
        <coordinates>
          <% points.each do |latitude, longitude| %>
          <%= longitude %>,<%= latitude %>,0
          <% end %>
        </coordinates>
      </LineString>
    </Placemark>

    <% route.stop_areas.each do |stop_area| %>
    <Placemark>
      <name><%= stop_area.name %></name>
      <styleUrl>#stoparea</styleUrl>
      <Point>
        <coordinates><%= stop_area.longitude %>,<%= stop_area.latitude %>,0.000000</coordinates>
      </Point>
    </Placemark>
    <% end %>
  </Document>
</kml>
ERB

puts ERB.new(kml_template).result binding
