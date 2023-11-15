#
# Usage:
#   expect(model).to exist_in_database
#
RSpec::Matchers.define :exist_in_database do
  match do |actual|
    actual.class.exists?(actual.id)
  end
end

#
# Usage:
#   expect(key: something).to include(key: a_string_eq_to("test"))
RSpec::Matchers.define :a_string_eq_to do |expected|
  match do |actual|
    actual.to_s == expected
  end
end

RSpec::Matchers.alias_matcher :an_array_including, :include
RSpec::Matchers.define_negated_matcher :an_array_excluding, :include
RSpec::Matchers.define_negated_matcher :not_change, :change
RSpec::Matchers.define_negated_matcher :not_change, :change
RSpec::Matchers.define_negated_matcher :not_raise_error, :raise_error
RSpec::Matchers.define_negated_matcher :a_string_not_matching, :a_string_matching

class SameAttributesMatcher
  def initialize(attribute_names, than:, named: nil, allow_nil: true)
    @attribute_names = attribute_names.flatten
    @than = than
    @allow_nil = allow_nil
    @named = named
  end

  def matches?(target)
    @target = target
    @other = other_instance(target)

    @attribute_names.all? do |name|
      @tested_attribute = name
      @expected_value = @other.send(name)
      @actual_value = @target.send(name)

      (@allow_nil || @expected_value.present?) &&
        @expected_value.eql?(@actual_value)
    end
  end

  def other_instance(target)
    if @than.respond_to?(:call)
      @than.call target
    else
      @than
    end
  end

  def failure(negated = false)
    if !@allow_nil && @expected_value.nil?
      "expected value for #{@tested_attribute} is nil"
    else
      verb = negated ? "matches" : "doesn't match"
      "#{@actual_value.inspect} #{verb} #{@expected_value.inspect}"
    end
  end

  def failure_message
    "expected #{@target.inspect} to have the same #{@tested_attribute} than #{@other.inspect} (but #{failure})"
  end

  def failure_message_when_negated
    "expected #{@target.inspect} to have a different #{@tested_attribute} than #{@other.inspect} (but #{failure(false)})"
  end

  def description
    attribute = "attribute"
    attribute += "s" if @attribute_names.many?
    "have the same #{attribute} #{@attribute_names.to_sentence} than the #{@named || @than.class.name}"
  end
end

module AttributesMatcher

  # Compare values of given attributes. The compared model can be retrieved by a Proc
  #
  # expect(copy).to have_same_attributes(:name, :parent_id, than: original)
  # expect(copies).to all(have_same_attributes(:name, :parent_id, than: ->(copy) { way_to_find_original(copy) } ))
  def have_same_attributes(*attribute_names, than:, named: nil, allow_nil: true)
    SameAttributesMatcher.new(attribute_names, than: than, allow_nil: allow_nil, named: named)
  end
end

RSpec.configure do |config|
  config.include(AttributesMatcher)
end
