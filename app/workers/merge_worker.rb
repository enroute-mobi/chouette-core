class MergeWorker
  include Sidekiq::Worker
  include Concerns::ImportantWorker

  def perform(id)
    merge = Merge.find(id)
    begin 
      merge.merge!
    rescue
      merge.failed!
    end
  end
end
