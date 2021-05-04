RSpec.describe Api::V1::DatasController, type: :controller do
  let(:file){ File.open(File.join(Rails.root, 'spec', 'fixtures', 'google-sample-feed.zip')) }
  let(:export){ create :gtfs_export, status: :successful, file: file}

  describe 'GET #info' do
    it 'should not be successful' do
      expect{ get :infos, params: { slug: :foo }}.to raise_error ActiveRecord::RecordNotFound
    end

    context 'with a publication_api' do
      it 'should be successful' do
        get :infos, params: { slug: create(:publication_api).slug }
        expect(response).to be_successful
      end
    end
  end

  context 'with a public API' do
    describe 'get #download_full' do
      let(:slug) { :foo }
      let(:key) { "gtfs" }
      let(:get_request) { get :download_full, params: { slug: slug, key: key }}

      it 'should not be successful' do
        expect{ get_request }.to raise_error ActiveRecord::RecordNotFound
      end

      context 'with a publication_api' do
        let(:publication_api) { create(:publication_api, public: true) }
        let(:publication) { create(:publication, publication_setup: create(:publication_setup, publish_per_line: false)) }

        let(:slug) { publication_api.slug }

        it 'should not be successful' do
          expect{ get_request }.to raise_error ActiveRecord::RecordNotFound
        end

        context 'with a publication_api_source' do
          before(:each) do
            create :publication_api_source, publication_api: publication_api, publication: publication, export: export
          end

          it 'should be successful' do
            get_request
            expect(response).to be_successful
          end
        end
      end
    end

    describe 'get #download_line' do
      let(:slug) { :foo }
      let(:key) { "536-gtfs" }
      let(:get_request) { get :download_line, params: { slug: slug, key: key }}

      it 'should not be successful' do
        expect{ get_request }.to raise_error ActiveRecord::RecordNotFound
      end

      context 'with a publication_api' do
        let(:publication_api) { create(:publication_api, public: true) }
        let(:publication) { create(:publication, publication_setup: create(:publication_setup, publish_per_line: true)) }
        let(:line) { create(:line, registration_number: "536") }
        let(:export_with_line){ create :gtfs_export, status: :successful, file: file, options: {line_ids: [line.id]}}
        let(:publication_api_key) { create :publication_api_key }

        let(:slug) { publication_api.slug }

        it 'should not be successful' do
          expect{ get_request }.to raise_error ActiveRecord::RecordNotFound
        end

        context 'with a publication_api_source' do
          before(:each) do
            create :publication_api_source, publication_api: publication_api, publication: publication, export: export_with_line
          end

          it 'should be successful' do
            get_request
            expect(response).to be_successful
          end
        end
      end
    end
  end

  context 'when needing authentication' do
    let(:auth_token) { 'token' }

    before do
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(auth_token)
    end

    describe 'get #download_full' do
      let(:slug) { :foo }
      let(:key) { "gtfs" }
      let(:get_request) { get :download_full, params: { slug: slug, key: key }}

      it 'should not be successful' do
        expect{ get_request }.to raise_error ActiveRecord::RecordNotFound
      end

      context 'with a publication_api' do
        let(:publication_api) { create(:publication_api) }
        let(:publication) { create(:publication, publication_setup: create(:publication_setup, publish_per_line: false)) }
        let(:publication_api_key) { create :publication_api_key }
        let(:auth_token) { publication_api_key.token }

        let(:slug) { publication_api.slug }

        it 'should not be successful' do
          get_request
          expect(response).to_not be_successful
        end

        context 'with a publication_api_source' do
          before(:each) do
            create :publication_api_source, publication_api: publication_api, publication: publication, export: export
          end

          it 'should not be successful' do
            get_request
            expect(response).to_not be_successful
          end

          context 'authenticated' do
            let(:publication_api_key) { create :publication_api_key, publication_api: publication_api }

            it 'should be successful' do
              get_request
              expect(response).to be_successful
            end
          end
        end
      end
    end

    describe 'get #download_line' do
      let(:slug) { :foo }
      let(:key) { "536-gtfs" }
      let(:get_request) { get :download_line, params: { slug: slug, key: key }}

      it 'should not be successful' do
        expect{ get_request }.to raise_error ActiveRecord::RecordNotFound
      end

      context 'with a publication_api' do
        let(:publication_api) { create(:publication_api) }
        let(:publication) { create(:publication, publication_setup: create(:publication_setup, publish_per_line: true)) }
        let(:line) { create(:line, registration_number: "536") }
        let(:export_with_line){ create :gtfs_export, status: :successful, file: file, options: {line_ids: [line.id]}}
        let(:publication_api_key) { create :publication_api_key }
        let(:auth_token) { publication_api_key.token }

        let(:slug) { publication_api.slug }

        it 'should not be successful' do
          get_request
          expect(response).to_not be_successful
        end

        context 'with a publication_api_source' do
          before(:each) do
            create :publication_api_source, publication_api: publication_api, publication: publication, export: export_with_line
          end

          it 'should not be successful' do
            get_request
            expect(response).to_not be_successful
          end

          context 'authenticated' do
            let(:publication_api_key) { create :publication_api_key, publication_api: publication_api }

            it 'should be successful' do
              get_request
              expect(response).to be_successful
            end
          end
        end
      end
    end

    describe 'get #lines' do
      let(:context) do
        Chouette.create do
          line :first
          line :second

          referential lines: [:first, :second]
        end
      end

      let(:referential) { context.referential }

      let(:first_line) { context.line(:first) }
      let(:second_line) { context.line(:second) }

      before do
        allow_any_instance_of(ReferentialSuite).to receive(:current).and_return(referential)
      end

      context 'with a publication_api' do

        let(:publication_api) { create(:publication_api, public: false, workgroup: context.workgroup) }

        context 'unauthenticated' do
          it 'should not be successful' do
            get( :lines, params: { slug: publication_api.slug, key:  "foo", :format => :json  })
            expect(response).to_not be_successful
          end
        end

        context 'authenticated' do
          let(:publication_api_key) { create :publication_api_key, publication_api: publication_api  }
          let(:auth_token) { publication_api_key.token }

          it 'should be successful' do
            get( :lines, params: { slug: publication_api.slug, key:  publication_api_key.token, :format => :json  })
            expect(response).to be_successful
          end

          it 'should render 2 lines with metadatas' do
            get( :lines, params: { slug: publication_api.slug, key:  publication_api_key.token, :format => :json })

            json = JSON.parse(response.body).map(&:with_indifferent_access)

            expect(json).to match_array([
              include(name: first_line.name, objectid: first_line.objectid, updated_at: a_value),
              include(name: second_line.name, objectid: second_line.objectid, updated_at: a_value)
              ])
            end

          end
        end
      end

    end

    context 'graphql requests' do
      let(:context) do
        Chouette.create do
          line :first
          line :second

          referential lines: [:first, :second] do
            route :r_first, line: :first
            route :r_second, line: :first
            route :r_third, line: :second
            route :r_fourth, line: :second
          end
        end
      end
      let(:publication_api) { create(:publication_api, public: true, workgroup: context.workgroup) }

      before do
        context.referential.switch
        allow_any_instance_of(ReferentialSuite).to receive(:current).and_return context.referential
      end

      let(:graphql_response) do
        post :graphql, params: {slug: publication_api.slug, query: query}
        JSON.parse response.body
      end

      let(:line_nodes) { graphql_response['data']['lines']['nodes'] }
      let(:first_line_node) { line_nodes.find { |n| n["objectid"] == context.line(:first).objectid } }
      let(:second_line_node) { line_nodes.find { |n| n["objectid"] == context.line(:second).objectid } }

      context 'serviceCounts' do
        before do
          [:r_first, :r_second].each do |route_s|
            ["2020-01-01", "2020-06-01", "2020-12-01", "2021-01-01", "2021-06-01", "2021-12-01"].each{ |d| create :stat_journey_pattern_courses_by_date, date: d.to_date, line: context.line(:first), route: context.route(route_s), count: 5 }
          end

          [:r_third, :r_fourth].each do |route_s|
            ["2021-01-01", "2021-06-01", "2021-12-01", "2022-01-01", "2022-06-01", "2022-12-01"].each{ |d| create :stat_journey_pattern_courses_by_date, date: d.to_date, line: context.line(:second), route: context.route(route_s), count: 5 }
          end
        end

        describe 'Lines -> ServiceCounts (Basic)' do
          let(:query) { <<~GQL
            {
              lines {
                nodes {
                  objectid
                  name
                  serviceCounts {
                    nodes {
                      date
                      count
                    }
                  }
                }
              }
            }
            GQL
          }

          it 'returns the right number of lines' do
            expect(line_nodes.count).to eq 2
          end

          it 'serviceCount returns the sum of JourneyPatternCoursesByDate objects having the same date and line_id' do
            expect(second_line_node["serviceCounts"]["nodes"].map{ |n| n["count"]}).to eq [10, 10, 10, 10, 10, 10]
          end

        end

        describe 'Lines -> ServiceCounts (Filters)' do

          let(:query) { <<~GQL
            {
              lines {
                nodes {
                  objectid
                  name
                  serviceCounts(from: "2022-01-01", to: "2023-01-31") {
                    edges {
                      node {
                        date
                        count
                      }
                      cursor
                    }

                    pageInfo {
                      endCursor
                      hasNextPage
                    }
                  }
                }
              }
            }
            GQL
          }

          before do
            create :stat_journey_pattern_courses_by_date, date: "2022-05-01".to_date, line: context.line(:second), route: context.route(:r_third), count: 5
          end

          it 'returns the right number of lines' do
            expect(line_nodes.count).to eq 2
          end

          it 'returns the right number of serviceCounts' do
            expect(second_line_node["serviceCounts"]["edges"].count).to eq 4
            expect(first_line_node["serviceCounts"]).to be_nil
          end

          it 'serviceCount returns the sum of JourneyPatternCoursesByDate objects having the same date and line_id' do
            service_counts = second_line_node["serviceCounts"]["edges"]
            expect(service_counts.find{|e| e["node"]["date"]=="2022-06-01"}["node"]["count"]).to eq 10
            expect(service_counts.find{|e| e["node"]["date"]=="2022-05-01"}["node"]["count"]).to eq 5
          end
        end

      end

      context 'serviceCountTotal' do

        before do
          [:r_first, :r_second].each do |route_s|
            ["2020-01-01", "2020-06-01", "2020-12-01", "2021-01-01", "2021-06-01", "2021-12-01"].each{ |d| create :stat_journey_pattern_courses_by_date, date: d.to_date, line: context.line(:first), route: context.route(route_s), count: 5 }
          end

          [:r_third, :r_fourth].each do |route_s|
            ["2021-01-01", "2021-06-01", "2021-12-01", "2022-01-01", "2022-06-01", "2022-12-01"].each{ |d| create :stat_journey_pattern_courses_by_date, date: d.to_date, line: context.line(:second), route: context.route(route_s), count: 5 }
          end
        end

        describe 'Lines -> ServiceCountTotal (Basic)' do
          let(:query) { <<~GQL
            {
              lines {
                nodes {
                  objectid
                  name
                  serviceCount
                }
              }
            }
            GQL
          }

          before do
            create :stat_journey_pattern_courses_by_date, date: "2022-05-01".to_date, line: context.line(:second), route: context.route(:r_third), count: 5
          end

          it 'returns the right total for serviceCount attribute' do
            expect(first_line_node["serviceCount"]).to eq 60
            expect(second_line_node["serviceCount"]).to eq 65
          end

        end

        describe 'Lines -> ServiceCountTotal (Filters)' do
          let(:query) { <<~GQL
            {
              lines {
                nodes {
                  objectid
                  name
                  serviceCount(from: "2021-12-01")
                }
              }
            }
            GQL
          }

          it 'returns the right total for serviceCount attribute' do
            expect(first_line_node["serviceCount"]).to eq 10
            expect(second_line_node["serviceCount"]).to eq 40
          end

        end

      end

      context 'stop areas' do

        it 'should return lines->routes->stop_areas when asked' do
          query = <<~GQL
          {
            lines {
              nodes {
                objectid
                routes {
                  nodes {
                    objectid
                    stopAreas {
                      nodes {
                        objectid
                      }
                    }
                  }
                }
                stopAreas {
                  nodes {
                    objectid
                  }
                }
              }
            }
          }
          GQL
          post :graphql, params: {slug: publication_api.slug, query: query}
          json = JSON.parse response.body
          data = json['data']['lines']
          expect(data['nodes'].count).to eq 2
          data['nodes'].each do |node|
            line = Chouette::Line.find_by(objectid: node['objectid'])
            expect(node['objectid']).to eq line.objectid
            expect(node['routes']['nodes'].count).to eq line.routes.count
            expect(node['stopAreas']['nodes'].count). to eq line.stop_areas.count
          end
        end

        it 'should return stop_areas->lines when asked' do
          query = <<~GQL
          {
            stopAreas {
              nodes {
                objectid
                lines {
                  nodes {
                    objectid
                  }
                }
              }
            }
          }
          GQL
          post :graphql, params: {slug: publication_api.slug, query: query}
          json = JSON.parse response.body
          data = json['data']['stopAreas']
          expect(data['nodes'].count).to eq(context.line(:first).stop_areas.count + context.line(:second).stop_areas.count)
        end
      end
    end
  end
