describe ApplicationController do

  controller do
    include JsonCollectionPagination
    def index
      collection = Changeset.where('')
      render paginated_json_collection(collection)
    end
    def url_for(params)
      ActionDispatch::Http::URL.url_for(only_path: true, params: params)
    end
    def query_params
      {}
    end
  end

  let(:pager) { Proc.new { |offset,per_page,total|
    get :index, offset: offset, per_page: per_page, total: total
    JSON.parse(response.body)
    }
  }

  context 'paginated_json_collection' do
    before(:each) do
      @changesets = create_list(:changeset, 10)
      @changeset_ids = @changesets.sort_by(&:id).map(&:id)
    end

    it 'one page' do
      get :index
      expect_json({
        changesets: -> (changesets) {
          expect(changesets.map { |i| i[:id] }).to eq(@changeset_ids[0...10])
        },
        meta: {
          sort_key: 'id',
          sort_order: 'asc',
          offset: 0,
          per_page: 50
        }
      })
    end

    it 'has an optional total' do
      get :index, total: true
      expect_json({
        changesets: -> (changesets) {
          expect(changesets.map { |i| i[:id] }).to eq(@changeset_ids[0...10])
        },
        meta: {
          sort_key: 'id',
          sort_order: 'asc',
          total: 10,
          offset: 0,
          per_page: 50
        }
      })
    end

    it 'sorts ascending' do
      get :index, sort_order: :asc, per_page: 5
      expect_json({
        changesets: -> (changesets) {
          expect(changesets.map { |i| i[:id] }).to eq(@changeset_ids[0...5])
        },
        meta: {
          sort_key: 'id',
          sort_order: 'asc',
          offset: 0,
          per_page: 5
        }
      })
    end

    it 'sorts descending' do
      get :index, sort_order: :desc, per_page: 5
      expect_json({
        changesets: -> (changesets) {
          expect(changesets.map { |i| i[:id] }).to eq(@changeset_ids.reverse[0...5])
        },
        meta: {
          sort_key: 'id',
          sort_order: 'desc',
          offset: 0,
          per_page: 5
        }
      })
    end

    it 'sort_min_id' do
      idx = 1
      per_page = 5
      sort_min_id = @changeset_ids[idx]
      next_sort_min_id = @changeset_ids[idx+per_page]
      get :index, sort_min_id: sort_min_id, per_page: per_page
      expect_json({
        changesets: -> (changesets) {
          expect(changesets.map { |i| i[:id] }).to eq(@changeset_ids[idx+1...idx+1+per_page])
        },
        meta: {
          sort_key: 'id',
          sort_order: 'asc',
          sort_min_id: sort_min_id,
          per_page: per_page,
          next: -> (next_url) {
            expect(next_url).to include("sort_min_id=#{next_sort_min_id}")
          }
        }
      })
    end

    it 'sort_min_id does not fail on empty result' do
      get :index, sort_min_id: @changeset_ids.last+1
      expect_json({
        changesets: -> (changesets) {
          expect(changesets.size).to eq(0)
        }
      })
      expect(response.code.to_i).to eq(200)
    end

    it 'raises ArgumentError on invalid sort_key' do
      expect {
        get :index, sort_key: :unknown_key
      }.to raise_error(ArgumentError)
    end

    it 'has a next page' do
      expect(pager.call(0,1,false)['meta']['next']).to include('offset=1')
      expect(pager.call(0,4,false)['meta']['next']).to include('offset=4')
      expect(pager.call(4,4,false)['meta']['next']).to include('offset=8')
      expect(pager.call(12,4,false)['meta']['next']).to be_nil
      expect(pager.call(0,15,false)['meta']['next']).to be_nil
    end

    it 'has a previous page' do
      expect(pager.call(0,1,false)['meta']['prev']).to be_nil
      expect(pager.call(0,4,false)['meta']['prev']).to be_nil
      expect(pager.call(4,4,false)['meta']['prev']).to include('offset=0')
      expect(pager.call(8,4,false)['meta']['prev']).to include('offset=4')
      expect(pager.call(0,15,false)['meta']['prev']).to be_nil
    end

    it 'will not underflow offset' do
      expect(pager.call(5,10,false)['meta']['prev']).to include('offset=0')
    end

    it 'allows pagination to be disabled' do
      get :index, per_page: '∞'
      expect_json({
        changesets: -> (changesets) {
          expect(changesets.map { |i| i[:id] }).to eq(@changeset_ids[0...10])
        },
        meta: {
          per_page: 'false'
        }
      })
    end
  end
end
