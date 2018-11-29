class AggregateWorker
  include Sidekiq::Worker
  include Concerns::ImportantWorker

  def perform(id)
    aggregate = Aggregate.find(id)
    begin
      aggregate.aggregate!
    rescue
      aggregate.failed!
    end
  end
end
