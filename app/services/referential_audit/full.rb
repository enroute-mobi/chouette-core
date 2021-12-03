class ReferentialAudit
  class Full
    def perform opts={}
      Chouette::Benchmark.measure("audit", referential_id: referential.id) do
        limit = opts.delete(:limit)
        referentials = Referential.mergeable.uniq
        referentials += Workbench.all.map { |w| w.output.current }.compact
        referentials += Workbench.all.map { |w| w.referential_to_aggregate }.compact
        referentials += Workgroup.all.map { |w| w.output.current }.compact
        referentials = referentials.uniq.sort_by(&:created_at).reverse
        out = []
        if limit
          if limit.is_a? Integer
            referentials = referentials[0...limit]
          elsif limit.is_a?(Time) || limit.is_a?(Date)
            referentials = referentials.select{|r| r.created_at > limit }
          end
        end

        referentials.each do |referential|
          audit = ReferentialAudit::FullReferential.new referential
          out << audit.perform(opts.dup.update({plain_output: true}))
        end

        out
      end
    end
  end
end
