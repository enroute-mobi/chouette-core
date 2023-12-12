namespace :generate do

  desc "Create model diagrams for Chouette"
  task :model_diagram  => :environment do
    sh "bundle exec rake erd only='Organisation,Referential,User,Workbench,Workgroup' filename='organisation' title='Organisation'"
    sh "bundle exec rake erd only='Calendar,Referential,ReferentialMetadata,Chouette::Line,Chouette::Route,Chouette::JourneyPattern,Chouette::VehicleJourney,Chouette::VehicleJourneyAtStop,Chouette::TimeTable,Chouette::TimeTableDate,Chouette::TimeTablePeriod,Chouette::Footnote,Chouette::Network,Chouette::Company,Chouette::StopPoint,Chouette::StopArea' filename='offer_datas' title='Offer Datas'"
    sh "bundle exec rake erd only='Organisation,StopAreaReferential,StopAreaReferentialMembership,LineReferential,LineReferentialMembership' filename='referentiels_externes' title='Référentiels externes'"
    sh "bundle exec rake erd only='Import::Netex,Import::Base,Import::Workbench,Import::Resource,Import::Message' filename='import' title='Import'"
    sh "bundle exec rake erd only='Organisation,Workgroup,Workbench,ReferentialSuite,Referential' filename='merge' title='Merge'"
    sh "bundle exec rake erd only='Export::Base,Export::Message,Export::Resource' filename='export' title='Export'"
    sh "bundle exec rake erd only='Workbench,Referential,ReferentialSuite,Merge' filename='merge' title='Merge'"
    #sh "bundle exec rake erd only='' filename='publication' title='Publication'"
  end

end
