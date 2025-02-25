collection @shapes

extends(
  'autocomplete/base',
  locals: {
    label_method: Proc.new { |s| truncate([s.name, s.uuid].compact.join(' | '), length: 30) }
  }
)

attribute :uuid