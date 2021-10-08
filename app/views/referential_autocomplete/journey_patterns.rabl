collection @journey_patterns

extends('autocomplete/base', locals: { label_method: Proc.new { |jp| "<strong>#{jp.published_name} - #{jp.get_objectid.short_id}</strong><br/><small>#{jp.registration_number}</small>" } })
extends('api/v1/journey_patterns/show')
