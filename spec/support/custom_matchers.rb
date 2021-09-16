#
# Usage:
#   expect(model).to exist_in_database
#
RSpec::Matchers.define :exist_in_database do

  match do |actual|
    actual.class.exists?(actual.id)
  end

end

RSpec::Matchers.alias_matcher :an_array_including, :include
RSpec::Matchers.define_negated_matcher :an_array_excluding, :include
RSpec::Matchers.define_negated_matcher :not_change, :change
RSpec::Matchers.define_negated_matcher :not_change, :change
RSpec::Matchers.define_negated_matcher :not_raise_error, :raise_error

class SameAttributesMatcher
  def initialize(attribute_names, than: )
    @attribute_names = attribute_names.flatten
    @than = than
  end
  def matches?(target)
    @target = target
    @other = other_instance(target)

    @attribute_names.all? do |name|
      @tested_attribute = name
      @expected_value = @other.send(name)
      @actual_value = @target.send(name)

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

  def failure_message
    "expected #{@target.inspect} to have the same #{@tested_attribute} than #{@other.inspect} (but #{@actual_value.inspect} doesn't match #{@expected_value.inspect})"
  end

  def failure_message_when_negated
    "expected #{@target.inspect} to have a different #{@tested_attribute} than #{@other.inspect} (but #{@actual_value.inspect} matches #{@expected_value.inspect})"
  end

  def description
    attribute = "attribute"
    attribute += "s" if @attribute_names.many?
    "have the same #{attribute} #{@attribute_names.to_sentence} than the #{@than.class.name}"
  end
end

module AttributesMatcher

  # Compare values of given attributes. The compared model can be retrieved by a Proc
  #
  # expect(copy).to have_same_attributes(:name, :parent_id, than: original)
  # expect(copies).to all(have_same_attributes(:name, :parent_id, than: ->(copy) { way_to_find_original(copy) } ))
  def have_same_attributes(*attribute_names, than:)
    SameAttributesMatcher.new(attribute_names, than: than)
  end

end

RSpec.configure do |config|
  config.include(AttributesMatcher)
end
