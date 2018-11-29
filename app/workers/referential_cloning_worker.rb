class ReferentialCloningWorker
  include Sidekiq::Worker
  include Concerns::ImportantWorker

  def perform(id)
    ref = ReferentialCloning.find(id)
    begin
      ref.clone_with_status!
    rescue
      ref.failed!
    end
  end
end
