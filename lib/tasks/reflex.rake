namespace :reflex do
  desc "Sync data from Reflex api"
  task sync: :environment  do
    sync = StopAreaReferential.find_by(name: 'Reflex').stop_area_referential_syncs.build
    raise "reflex:sync aborted - There is already an synchronisation in progress" unless sync.valid?
    sync.save if sync.valid?
  end
end
