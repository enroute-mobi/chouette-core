collection @vehicle_journeys

extends('autocomplete/base', locals: { label_method: Proc.new { |vj| vj.get_objectid.short_id } })

attributes :objectid
