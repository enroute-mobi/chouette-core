class MergeContext
  attr_accessor :merge_method, :skip_cloning

  def initialize(attributes = {}, &block)
    attributes.reverse_merge!(merge_method: 'legacy', skip_cloning: true)
    attributes.each { |k,v| send "#{k}=", v }

    @context_block = block
  end

  def create_context
    Chouette.create(&@context_block).tap do |context_block|
      context_block.referential(:source).tap do |source|
        source.switch do
          Chouette::ChecksumUpdater.new(source).update
        end
      end
    end
  end

  def context
    @context ||= create_context
  end

  def create_merge
    attributes = {
      created_at: Time.now,
      workbench: context.workbench,
      referentials: [source],
      new: new,
      merge_method: merge_method.to_s
    }

    if skip_cloning
      attributes.delete :new
      context.workbench.output.update current: new
    end

    Merge.new attributes
  end

  def merge
    @merge ||= create_merge
  end

  def method_missing(name, *arguments)
    if name =~ /^(.*)_(route|journey_pattern|vehicle_journey)$/
      referential_name = $1
      referential = referential_name == 'source' ? source : new
      referential.switch { context.instance(name)&.reload }
    else
      super
    end
  end

  def source
    @source ||= context.instance(:source)
  end

  def new
    @new ||= context.instance(:new)
  end

  def print_status
    puts "In Source referential"
    source.switch do
      ap Chouette::Route.all
      ap Chouette::JourneyPattern.all
      ap Chouette::VehicleJourney.all
    end

    puts "In New referential"
    new.switch do
      ap Chouette::Route.all
      ap Chouette::JourneyPattern.all
      ap Chouette::VehicleJourney.all
    end
  end
end
