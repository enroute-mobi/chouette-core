module Chouette::Netex::Concerns::Helpers
  def format_time(time)
    time.utc.strftime('%Y-%m-%dT%H:%M:%S.%1NZ')
  end

  def id_with_entity(model, entity_name)
    model.objectid.gsub(model.class.name.demodulize, entity_name)
  end
end
