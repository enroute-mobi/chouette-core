module RGeoExt
  def self.geographic_factory
    @@geographic_factory ||= RGeo::Geographic.spherical_factory(
      wkt_parser: { support_ewkt: true, default_srid: 4326 },
      wkt_generator: { type_format: :ewkt, emit_ewkt_srid: true },
      wkb_parser: { support_ewkb: true, default_srid: 4326 },
      wkb_generator: { type_format: :ewkb, emit_ewkb_srid: true }
    )
  end
end
