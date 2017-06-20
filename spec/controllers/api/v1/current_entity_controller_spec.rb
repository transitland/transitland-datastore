describe Api::V1::CurrentEntityController do
  controller do
    def self.model
      Stop
    end
    def url_for(params)
      "http://blah/offset=#{params[:offset]}"
    end
  end

  before(:each) do
    @glen_park = create(:stop, geometry: 'POINT(-122.433416 37.732525)', name: 'Glen Park')
    @bosworth_diamond = create(:stop, geometry: 'POINT(-122.434011 37.733595)', name: 'Bosworth + Diamond')
    @metro_embarcadero = create(:stop, geometry: 'POINT(-122.396431 37.793152)', name: 'Metro Embarcadero')
    @gilman_paul_3rd = create(:stop, geometry: 'POINT(-122.395644 37.722413)', name: 'Gilman + Paul + 3rd St.')
    @glen_park.update(tags: { wheelchair_accessible: 'yes' })
    @gilman_paul_3rd.update(tags: { wheelchair_accessible: 'no' })
  end

  context 'GET index' do
    context 'base' do
      it 'returns all entities' do
        get :index, total: true
        expect_json_types({ stops: :array })
        expect_json({
          stops: -> (stops) {
            expect(stops.length).to eq 4
          },
          meta: {
            total: 4
          }
        })
      end
    end

    context '?onestop_id' do
      it 'returns entities by onestop_id' do
        onestop_id = @glen_park.onestop_id
        get :index, onestop_id: onestop_id
        expect_json_types({ stops: :array })
        expect_json({
          stops: -> (stops) {
            expect(stops.length).to eq(1)
            expect(stops.first[:onestop_id]).to eq onestop_id
          }
        })
      end
    end

    context '?lat ?lon ?r' do
      it 'returns entities within a radius of a point' do
        get :index, lat: 37.732520, lon: -122.433415, r: 500
        expect_json({ stops: -> (stops) {
          expect(stops.map { |stop| stop[:onestop_id] }).to match_array([@glen_park, @bosworth_diamond].map(&:onestop_id))
        }})
      end
    end

    context '?bbox' do
      it 'returns entities inside a bbox' do
        get :index, bbox: '-122.4131,37.7136,-122.3789,37.8065'
        expect_json({ stops: -> (stops) {
          expect(stops.map { |stop| stop[:onestop_id] }).to match_array([@metro_embarcadero, @gilman_paul_3rd].map(&:onestop_id))
        }})
      end
    end

    context '?tag_key ?tag_value' do
      it 'returns entities with a given tag' do
        get :index, tag_key: 'wheelchair_accessible'
        expect_json({ stops: -> (stops) {
          expect(stops.map { |stop| stop[:onestop_id] }).to match_array([@glen_park.onestop_id, @gilman_paul_3rd.onestop_id])
        }})
      end

      it 'returns entities with a given tag value' do
        get :index, tag_key: 'wheelchair_accessible', tag_value: 'yes'
        expect_json({ stops: -> (stops) {
          expect(stops.map { |stop| stop[:onestop_id] }).to match_array([@glen_park.onestop_id])
        }})
      end
    end

    context '?imported_with_gtfs_id' do
      it 'returns entities with a given GTFS ID' do
        stop = Stop.first
        feed_version = create(:feed_version_example)
        feed_version.entities_imported_from_feed.create!(entity: stop, feed: feed_version.feed, gtfs_id: "test")
        get :index, imported_with_gtfs_id: 'test'
        expect_json({ stops: -> (stops) {
          expect(stops.first[:onestop_id]).to eq stop.onestop_id
          expect(stops.count).to eq 1
        }})
        get :index, imported_with_gtfs_id: 'true', gtfs_id: 'test'
        expect_json({ stops: -> (stops) {
          expect(stops.first[:onestop_id]).to eq stop.onestop_id
          expect(stops.count).to eq 1
        }})
        get :index, imported_with_gtfs_id: 'unknown'
        expect_json({ stops: -> (stops) {
          expect(stops.size).to eq 0
        }})
      end
    end
  end

  context '?format' do
    context 'geojson' do
      it 'should return GeoJSON' do
        stops = Stop.all.sort_by(&:id)
        get :index, format: :geojson
        expect_json({
          type: 'FeatureCollection',
          features: -> (features) {
            features.zip(stops) { |i,j|
              expect(i[:properties][:onestop_id]).to eq(j.onestop_id)
              expect(i[:geometry]).to eq(j.geometry)
            }
          }
        })
      end

      it '?bbox' do
        get :index, format: :geojson, bbox: '-122.4131,37.7136,-122.3789,37.8065'
        expect_json({
          type: 'FeatureCollection',
          features: -> (features) {
            expect(features.map { |feature| feature[:id] }).to match_array([@metro_embarcadero, @gilman_paul_3rd].map(&:onestop_id))
          }
        })
      end
    end

    context 'csv' do
      before(:each) do
        @sfmta = create(:operator, geometry: 'POINT(-122.395644 37.722413)', name: 'SFMTA')
        @metro_embarcadero.operators << @sfmta
      end

      it 'should return a CSV file for download' do
        get :index, format: :csv
        expect(response.headers['Content-Type']).to eq 'text/csv'
        expect(response.headers['Content-Disposition']).to eq 'attachment; filename=stops.csv'
      end

      it 'should include column headers and row values' do
        get :index, format: :csv, bbox: '-122.4131,37.7136,-122.3789,37.8065'
        expect(response.body.lines.count).to eq 3
        expect(response.body).to start_with('Onestop ID,Name,Operators serving stop (names),Operators serving stop (Onestop IDs),Latitude (centroid),Longitude (centroid)')
        expect(response.body).to include("#{@metro_embarcadero.onestop_id},#{@metro_embarcadero.name},#{@sfmta.name},#{@sfmta.onestop_id},#{@metro_embarcadero.geometry(as: :wkt).lat},#{@metro_embarcadero.geometry(as: :wkt).lon}")
      end
    end
  end

  context '?include ?exclude' do
    it 'includes issues' do
      stop = Stop.first
      Issue.create!(issue_type: 'stop_name').entities_with_issues.create!(entity: stop, entity_attribute: 'name')
      get :index, include: 'issues'
      expect_json({stops: -> (stops) {
        expect(stops.first[:issues].size).to eq 1
      }})
      get :index, embed_issues: 'true'
      expect_json({stops: -> (stops) {
        expect(stops.first[:issues].size).to eq 1
      }})
    end

    it 'excludes issues' do
      stop = Stop.first
      Issue.create!(issue_type: 'stop_name').entities_with_issues.create!(entity: stop, entity_attribute: 'name')
      get :index, exclude: 'issues'
      expect_json({stops: -> (stops) {
        expect(stops.first[:issues]).to be_nil
      }})
      get :index, embed_issues: 'false'
      expect_json({stops: -> (stops) {
        expect(stops.first[:issues]).to be_nil
      }})
    end

    it 'includes geometry' do
      get :index, include: 'geometry'
      expect_json({ stops: -> (stops) {
        expect(stops.first.has_key?(:geometry)).to be true
      }})
      get :index, include_geometry: "true"
      expect_json({ stops: -> (stops) {
        expect(stops.first.has_key?(:geometry)).to be true
      }})
      get :index, exclude_geometry: "false"
      expect_json({ stops: -> (stops) {
        expect(stops.first.has_key?(:geometry)).to be true
      }})
    end

    it 'excludes geometry' do
      get :index, exclude: 'geometry'
      expect_json({ stops: -> (stops) {
        expect(stops.first.has_key?(:geometry)).to be false
      }})
      get :index, exclude_geometry: "true"
      expect_json({ stops: -> (stops) {
        expect(stops.first.has_key?(:geometry)).to be false
      }})
      get :index, include_geometry: "false"
      expect_json({ stops: -> (stops) {
        expect(stops.first.has_key?(:geometry)).to be false
      }})
    end
  end

  describe 'GET show' do
    it 'returns a single entity' do
      get :show, id: @metro_embarcadero.onestop_id
      expect_json_types({
        onestop_id: :string,
        geometry: :object,
        name: :string,
        created_at: :date,
        updated_at: :date
      })
      expect_json({ onestop_id: -> (onestop_id) {
        expect(onestop_id).to eq @metro_embarcadero.onestop_id
      }})
    end

    it 'returns a 404 when not found' do
      get :show, id: 'ntd9015-2053'
      expect(response.status).to eq 404
    end
  end
end
