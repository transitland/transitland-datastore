class FakePaginationCollection
  attr_accessor :items

  def initialize(items)
    @items = items
    @offset = 0
    @limit = @items.size
  end
  def column_names
    ['id']
  end
  def reorder(**kwargs)
    sort_key, sort_order = kwargs.first
    @items = @items.sort
    if sort_order.to_sym == :desc
      @items = @items.reverse
    end
    self
  end
  def offset(i)
    @offset = i
    self
  end
  def limit(i)
    @limit = i
    @items[@offset, @limit]
  end
  def count
    @items[@offset, @limit].size
  end
  def to_a
    @items
  end
end

describe ApplicationController do

  controller do
    include JsonCollectionPagination
    def index
      collection = FakePaginationCollection.new((0...15).to_a)
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
    it 'one page' do
      get :index
      expect_json({
        anonymous: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
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
        anonymous: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
        meta: {
          sort_key: 'id',
          sort_order: 'asc',
          total: 15,
          offset: 0,
          per_page: 50
        }
      })
    end

    it 'sorts ascending' do
      get :index, sort_order: :asc, per_page: 10
      expect_json({
        anonymous: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        meta: {
          sort_key: 'id',
          sort_order: 'asc',
          offset: 0,
          per_page: 10
        }
      })
    end

    it 'sorts descending' do
      get :index, sort_order: :desc, per_page: 10
      expect_json({
        anonymous: [14, 13, 12, 11, 10, 9, 8, 7, 6, 5],
        meta: {
          sort_key: 'id',
          sort_order: 'desc',
          offset: 0,
          per_page: 10
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
        anonymous: -> (items) { expect(items.count).to eq(15) },
        meta: {
          per_page: '∞'
        }
      })
    end
  end
end
