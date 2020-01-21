RSpec::Matchers.define :be_uniq do
  match do |actual|
    values_match? actual.uniq, actual
  end

  failure_message do |actual|
    diff = actual.to_a.dup
    actual.uniq.each { |value| diff.delete_at diff.index(value) }
    diff = diff.uniq
    "expected that #{actual.inspect} to be uniq, but found the following repeated elements: #{diff.inspect}"
  end
end
