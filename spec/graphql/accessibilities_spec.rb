RSpec.describe Types::AccessibilityType do
  describe ".accesibilities" do

    let(:context) do
      Chouette.create do
        stop_area :first, objectid: 'first', mobility_impaired_accessibility: 'yes', wheelchair_accessibility: 'yes'
        stop_area :second, objectid: 'second'

        referential do
          route stop_areas: [:first, :second] do
            journey_pattern
          end
        end
      end
    end

    let(:ctx) do
      { target_referential: context.referential }
    end

    def stop_area(name)
      context.stop_area(name)
    end

    let(:query) do
      <<~JSON
        {
          stopAreas {
            nodes {
              objectid
              accessibilities {
                mobilityImpairedAccessibility
                wheelchairAccessibility
              }
            }
          }
        }
      JSON
    end

    subject do
      ChouetteSchema
        .execute(query, variables: {}, context: ctx)
        .to_h
        .dig('data', 'stopAreas', 'nodes')
        .find { |e| e == expected_reponse}
        .present?
    end

    let(:expected_reponse) do
      {
        "objectid"=>"first:::LOC",
        "accessibilities"=>{
          "mobilityImpairedAccessibility"=>"yes",
          "wheelchairAccessibility"=>"yes"
        }
      }
    end

    it { is_expected.to be_truthy }
  end
end