class FakePaginationCollection
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
end

describe JsonCollectionPagination do

  before do
    class FakeController < ApplicationController
      include JsonCollectionPagination
    end
  end
  after { Object.send :remove_const, :FakeController }
  let(:object) { FakeController.new }
  let(:path_helper) { Proc.new { |params| "http://blah/offset=#{params[:offset]}" } }
  let(:collection) { FakePaginationCollection.new((0...10).to_a) }
  let(:collection_shuffle) { FakePaginationCollection.new((0...10).to_a.shuffle) }
  let(:pager) { Proc.new { |offset,per_page,total| object.send(:paginated_json_collection, collection, path_helper, nil, nil, offset, per_page, total, {}) } }

  context 'paginated_json_collection' do
    it 'one page' do
      expect(
        object.send(:paginated_json_collection, collection, path_helper, nil, nil, 0, 10, false, {})
      ).to eq({
        json: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        meta: {
          offset: 0,
          per_page: 10
        }
      })
    end

    it 'applies default sort order' do
      expect(
        object.send(:paginated_json_collection, collection_shuffle, path_helper, nil, nil, 4, 4, false, {})
      ).to eq({
        json: [4,5,6,7],
        meta: {
          offset: 4,
          per_page: 4,
          next: 'http://blah/offset=8',
          prev: 'http://blah/offset=0'
        }
      })
    end

    it 'has an optional total' do
      expect(
        object.send(:paginated_json_collection, collection, path_helper, nil, nil, 0, 10, true, {})
      ).to eq({
        json: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        meta: {
          total: 10,
          offset: 0,
          per_page: 10
        }
      })

      expect(
        object.send(:paginated_json_collection, collection, path_helper, nil, nil, 0, 10, false, {})
      ).to eq({
        json: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        meta: {
          offset: 0,
          per_page: 10
        }
      })
    end

    it 'sorts ascending' do
      expect(
        object.send(:paginated_json_collection, collection, path_helper, 'id', 'asc', 0, 10, false, {})[:json]
      ).to eq(
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
      )
    end

    it 'sorts descending' do
      expect(
        object.send(:paginated_json_collection, collection, path_helper, 'id', 'desc', 0, 10, false, {})[:json]
      ).to eq(
        [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]
      )
    end

    it 'raises ArgumentError on invalid sort_key' do
      expect {
        object.send(:paginated_json_collection, collection, path_helper, 'unknown_key', 'desc', 0, 10, false, {})
      }.to raise_error(ArgumentError)
    end

    it 'has a next page' do
      expect(pager.call(0,1,false)[:meta][:next]).to eq('http://blah/offset=1')
      expect(pager.call(0,4,false)[:meta][:next]).to eq('http://blah/offset=4')
      expect(pager.call(4,4,false)[:meta][:next]).to eq('http://blah/offset=8')
      expect(pager.call(8,4,false)[:meta][:next]).to be_nil
      expect(pager.call(0,10,false)[:meta][:next]).to be_nil
    end

    it 'has a previous page' do
      expect(pager.call(0,1,false)[:meta][:prev]).to be_nil
      expect(pager.call(0,4,false)[:meta][:prev]).to be_nil
      expect(pager.call(4,4,false)[:meta][:prev]).to eq('http://blah/offset=0')
      expect(pager.call(8,4,false)[:meta][:prev]).to eq('http://blah/offset=4')
      expect(pager.call(0,10,false)[:meta][:prev]).to be_nil
    end

    it 'will not underflow offset' do
      expect(pager.call(5,10,false)[:meta][:prev]).to eq('http://blah/offset=0')
    end
  end
end
