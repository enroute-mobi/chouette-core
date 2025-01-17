# frozen_string_literal: true

RSpec.describe Api::V1::DatasController, type: :controller do
  let(:publication_api) { context.publication_api }
  let(:publication) { context.publication }
  let(:gtfs_export_file) { fixture_file_upload('OFFRE_TRANSDEV_2017030112251.zip') }
  let(:gtfs_export) { create(:gtfs_export, file: gtfs_export_file) }
  let(:publication_api_source_gtfs) do
    publication_api.publication_api_sources.create!(publication: publication, export: gtfs_export, key: 'gtfs.zip')
  end

  describe 'GET #info' do
    it 'should not be successful' do
      expect{ get :infos, params: { slug: :foo }}.to raise_error ActiveRecord::RecordNotFound
    end

    context 'with a publication_api' do
      let(:context) do
        Chouette.create { publication_api }
      end

      it 'should be successful' do
        get :infos, params: { slug: publication_api.slug }
        expect(response).to be_successful
      end
    end
  end

  context 'with a public API' do
    describe 'get #download' do
      let(:slug) { :foo }
      let(:key) { "gtfs.zip" }
      let(:get_request) { get :download, params: { slug: slug, key: key }}

      it 'should not be successful without a publication_api_source' do
        expect{ get_request }.to raise_error ActiveRecord::RecordNotFound
      end

      context 'with a publication_api_source' do
        let(:context) do
          Chouette.create do
            publication_api public: true
            referential :referential
            publication referential: :referential
          end
        end
        let(:slug) { publication_api.slug }

        before { publication_api_source_gtfs }

        it 'should be successful' do
          get_request
          expect(response).to be_successful
          expect(response.body).to eq(gtfs_export.file.read)
        end

        context 'without export file' do
          let(:gtfs_export_file) { nil }

          it 'should not be successful' do
            get_request
            expect(response).to have_http_status(:not_found)
            expect(response.content_type).to eq('text/html')
            expect(response).to render_template('missing_file_error.html.slim', layout: 'layouts/api')
          end
        end
      end
    end

    describe 'get #redirect' do

    end
  end

  context 'with a secured API' do

    describe 'get #download' do
      let(:context) do
        Chouette.create do
          publication_api public: false
          referential :referential
          publication referential: :referential
        end
      end
      let(:slug) { publication_api.slug }
      let(:key) { "gtfs.zip" }
      let(:get_request) { get :download, params: { slug: slug, key: key }}

      before do
        publication_api_source_gtfs
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(auth_token)
      end

      context 'with good credentials' do
        let(:auth_token) { publication_api.api_keys.first.token }

        it 'should be successful' do
          get_request
          expect(response).to be_successful
          expect(response.body).to eq(gtfs_export.file.read)
        end
      end

      context 'whith bad credentials' do
        let(:auth_token) { 'token' }

        it 'should not be successful' do
          get_request
          expect(response).to_not be_successful
          expect(response).to render_template('invalid_authentication_error')
        end
      end

      context 'without credentials' do
        let(:auth_token) { nil }

        it 'should not be successful' do
          get_request
          expect(response).to_not be_successful
          expect(response).to render_template('missing_authentication_error')
        end
      end
    end

    describe 'get #lines' do
      let(:context) do
        Chouette.create do
          publication_api public: false

          line :first
          line :second

          referential lines: [:first, :second]
        end
      end

      let(:referential) { context.referential }

      let(:first_line) { context.line(:first) }
      let(:second_line) { context.line(:second) }

      before do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(auth_token)
        allow_any_instance_of(ReferentialSuite).to receive(:current).and_return(referential)
      end

      context 'with a publication_api' do
        context 'unauthenticated' do
          let(:auth_token) { "foo" }

          it 'should not be successful' do
            get( :lines, params: { slug: publication_api.slug, :format => :json  })
            expect(response).to_not be_successful
          end
        end

        context 'authenticated' do
          let(:auth_token) { publication_api.api_keys.first.token }

          it 'should be successful' do
            get( :lines, params: { slug: publication_api.slug, :format => :json  })
            expect(response).to be_successful
          end

          it 'should render 2 lines with metadatas' do
            get( :lines, params: { slug: publication_api.slug, :format => :json })

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
          publication_api public: true

          line :first
          line :second

          referential lines: [:first, :second] do
            route :r_first, line: :first do
              journey_pattern :jp_first
            end
            route :r_second, line: :first do
              journey_pattern :jp_second
            end
            route :r_third, line: :second do
              journey_pattern :jp_third
            end
            route :r_fourth, line: :second do
              journey_pattern :jp_fourth
            end
          end
        end
      end

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
            %w[2020-01-01 2020-06-01 2020-12-01 2021-01-01 2021-06-01 2021-12-01].each do |d|
              create(
                :service_count,
                date: d.to_date,
                line: context.line(:first),
                route: context.route(route_s),
                journey_pattern: context.route(route_s).journey_patterns.first,
                count: 5
              )
            end
          end

          [:r_third, :r_fourth].each do |route_s|
            %w[2021-01-01 2021-06-01 2021-12-01 2022-01-01 2022-06-01 2022-12-01].each do |d|
              create(
                :service_count,
                date: d.to_date,
                line: context.line(:second),
                route: context.route(route_s),
                journey_pattern: context.route(route_s).journey_patterns.first,
                count: 5
              )
            end
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

          it 'serviceCount returns the sum of ServiceCount objects having the same date and line_id' do
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
            create(
              :service_count,
              date: '2022-05-01'.to_date,
              line: context.line(:second),
              route: context.route(:r_third),
              journey_pattern: context.journey_pattern(:jp_third),
              count: 5
            )
          end

          it 'returns the right number of lines' do
            expect(line_nodes.count).to eq 2
          end

          it 'returns the right number of serviceCounts' do
            expect(second_line_node["serviceCounts"]["edges"].count).to eq 4
            expect(first_line_node["serviceCounts"]).to be_nil
          end

          it 'serviceCount returns the sum of ServiceCount objects having the same date and line_id' do
            service_counts = second_line_node["serviceCounts"]["edges"]
            expect(service_counts.find{|e| e["node"]["date"]=="2022-06-01"}["node"]["count"]).to eq 10
            expect(service_counts.find{|e| e["node"]["date"]=="2022-05-01"}["node"]["count"]).to eq 5
          end
        end

      end

      context 'serviceCountTotal' do

        before do
          [:r_first, :r_second].each do |route_s|
            %w[2020-01-01 2020-06-01 2020-12-01 2021-01-01 2021-06-01 2021-12-01].each do |d|
              create(
                :service_count,
                date: d.to_date,
                line: context.line(:first),
                route: context.route(route_s),
                journey_pattern: context.route(route_s).journey_patterns.first,
                count: 5
              )
            end
          end

          [:r_third, :r_fourth].each do |route_s|
            %w[2021-01-01 2021-06-01 2021-12-01 2022-01-01 2022-06-01 2022-12-01].each do |d|
              create(
                :service_count,
                date: d.to_date,
                line: context.line(:second),
                route: context.route(route_s),
                journey_pattern: context.route(route_s).journey_patterns.first,
                count: 5
              )
            end
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
            create(
              :service_count,
              date: '2022-05-01'.to_date,
              line: context.line(:second),
              route: context.route(:r_third),
              journey_pattern: context.journey_pattern(:jp_third),
              count: 5
            )
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

        it 'should return stop_areas -> custom_fields when asked' do

          context.workgroup.custom_fields.create(
            code: 'test',
            name: 'Test',
            field_type: 'string',
            resource_type: 'StopArea'
          )

          context.line(:first).stop_areas.first.update(custom_field_values: { test: 'foo'})

          query = <<~GQL
          {
            stopAreas {
              nodes {
                customFields
              }
            }
          }
          GQL

          post :graphql, params: {slug: publication_api.slug, query: query}
          json = JSON.parse response.body
          stop_areas = json['data']['stopAreas']['nodes']

          expect(stop_areas).to include({"customFields"=>{"test"=>"foo"}})
        end
      end
    end
  end
