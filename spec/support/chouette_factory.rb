module Chouette
  def self.create(&block)
    Chouette::Factory.create(&block)
  end
end
