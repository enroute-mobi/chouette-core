class MergeWorker
  include Sidekiq::Worker
  include Concerns::ImportantWorker

  def perform(id)
    Merge.find(id).merge!
  end
end
