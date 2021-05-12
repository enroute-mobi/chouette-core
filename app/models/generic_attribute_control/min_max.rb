# See CHOUETTE-513
# module GenericAttributeControl
#   class MinMax < ComplianceControl
#     store_accessor :control_attributes, :minimum, :maximum, :target
#
#     validates :target, presence: true
#     include MinMaxValuesValidation
#
#     class << self
#       def attribute_type; :integer end
#       def default_code; "3-Generic-2" end
#     end
#   end
# end
