class ImportResource < ActiveRecord::Base
  include AASM
  belongs_to :import

  extend Enumerize
  enumerize :status, in: %i(new pending successful failed)

  validates_presence_of :name, :type, :reference

  aasm column: :status do
    state :new, :initial => true
    state :pending
    state :successful
    state :failed

    event :run do
      transitions :from => [:new, :failed], :to => :pending
    end

    event :successful do
      transitions :from => [:pending, :failed], :to => :successful
    end

    event :failed do
      transitions :from => :pending, :to => :failed
    end
  end
end
