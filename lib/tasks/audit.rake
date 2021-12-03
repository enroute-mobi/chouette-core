desc "Audit *all* local referentials"
task :audit => :environment do
  Referential.where(ready: true).order("created_from_id asc").find_each do |referential|
    # puts "Audit '#{referential.name}' #{referential.id}/#{referential.slug}"

    referential_audit = ReferentialAudit::FullReferential.new(referential)
    referential_audit.perform(plain_output: true)

    if referential_audit.status != :success
      referential_audit.print_state
    end
  end
end

namespace :referential do
  desc "Audit the specified referential (by id or slug)"
  task :audit, [:id_or_slug] => :environment do |_, args|
    id_or_slug = args[:id_or_slug]
    referential = Referential.find_by(id: id_or_slug) || Referential.find_by(slug: id_or_slug)
    if referential
      ReferentialAudit::FullReferential.new(referential).perform
    else
      puts "Can't find Referential '#{id_or_slug}'"
    end
  end
end
