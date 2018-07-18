class ReferentialCloningWorker
  include Sidekiq::Worker
  include Concerns::ImportantWorker

  def perform(id)
    ReferentialCloning.find(id).clone_with_status!
  end
end
