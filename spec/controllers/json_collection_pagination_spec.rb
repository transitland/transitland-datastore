describe ApplicationController do

  controller do
    include JsonCollectionPagination
    def index
      collection = Changeset.where('')
      render paginated_json_collection(collection)
    end
    def url_for(params)
      "http://blah/offset=#{params[:offset]}"
    end
  end

  let(:pager) { Proc.new { |offset,per_page,total|
    get :index, offset: offset, per_page: per_page, total: total
    JSON.parse(response.body)
    }
  }

  context 'paginated_json_collection' do
    before(:each) do
      @issues = create_list(:changeset, 10)
      @issue_ids = @issues.sort_by(&:id).map(&:id)
    end

    it 'one page' do
      get :index
      expect_json({
        changesets: -> (changesets) {
          expect(changesets.map { |i| i[:id] }).to eq(@issue_ids[0...10])
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
          expect(changesets.map { |i| i[:id] }).to eq(@issue_ids[0...10])
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
          expect(changesets.map { |i| i[:id] }).to eq(@issue_ids[0...5])
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
          expect(changesets.map { |i| i[:id] }).to eq(@issue_ids.reverse[0...5])
        },
        meta: {
          sort_key: 'id',
          sort_order: 'desc',
          offset: 0,
          per_page: 5
        }
      })
    end

    it 'raises ArgumentError on invalid sort_key' do
      expect {
        get :index, sort_key: :unknown_key
      }.to raise_error(ArgumentError)
    end

    it 'has a next page' do
      expect(pager.call(0,1,false)['meta']['next']).to eq('http://blah/offset=1')
      expect(pager.call(0,4,false)['meta']['next']).to eq('http://blah/offset=4')
      expect(pager.call(4,4,false)['meta']['next']).to eq('http://blah/offset=8')
      expect(pager.call(12,4,false)['meta']['next']).to be_nil
      expect(pager.call(0,15,false)['meta']['next']).to be_nil
    end

    it 'has a previous page' do
      expect(pager.call(0,1,false)['meta']['prev']).to be_nil
      expect(pager.call(0,4,false)['meta']['prev']).to be_nil
      expect(pager.call(4,4,false)['meta']['prev']).to eq('http://blah/offset=0')
      expect(pager.call(8,4,false)['meta']['prev']).to eq('http://blah/offset=4')
      expect(pager.call(0,15,false)['meta']['prev']).to be_nil
    end

    it 'will not underflow offset' do
      expect(pager.call(5,10,false)['meta']['prev']).to eq('http://blah/offset=0')
    end

    it 'allows pagination to be disabled' do
      get :index, per_page: '∞'
      expect_json({
        changesets: -> (changesets) {
          expect(changesets.map { |i| i[:id] }).to eq(@issue_ids[0...10])
        },
        meta: {
          per_page: '∞'
        }
      })
    end
  end
end
