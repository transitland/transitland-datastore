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
  let(:collection) { FakePaginationCollection.new((0...15).to_a) }
  let(:collection_shuffle) { FakePaginationCollection.new((0...15).to_a.shuffle) }
  let(:pager) { Proc.new { |offset,per_page,total| object.send(:paginated_json_collection, collection, path_helper, nil, nil, offset, per_page, total, {}) } }

  context 'paginated_json_collection' do
    it 'one page' do
      expect(
        object.send(:paginated_json_collection, collection, path_helper, nil, nil, 0, 15, false, {})
      ).to eq({
        json: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
        meta: {
          sort_key: :id,
          sort_order: :asc,
          offset: 0,
          per_page: 15
        }
      })
    end

    it 'has an optional total' do
      expect(
        object.send(:paginated_json_collection, collection, path_helper, nil, nil, 0, 20, true, {})
      ).to eq({
        json: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
        meta: {
          sort_key: :id,
          sort_order: :asc,
          total: 15,
          offset: 0,
          per_page: 20
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
        [14, 13, 12, 11, 10, 9, 8, 7, 6, 5]
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
      expect(pager.call(12,4,false)[:meta][:next]).to be_nil
      expect(pager.call(0,15,false)[:meta][:next]).to be_nil
    end

    it 'has a previous page' do
      expect(pager.call(0,1,false)[:meta][:prev]).to be_nil
      expect(pager.call(0,4,false)[:meta][:prev]).to be_nil
      expect(pager.call(4,4,false)[:meta][:prev]).to eq('http://blah/offset=0')
      expect(pager.call(8,4,false)[:meta][:prev]).to eq('http://blah/offset=4')
      expect(pager.call(0,15,false)[:meta][:prev]).to be_nil
    end

    it 'will not underflow offset' do
      expect(pager.call(5,10,false)[:meta][:prev]).to eq('http://blah/offset=0')
    end

    it 'allows pagination to be disabled' do
      data = object.send(:paginated_json_collection, collection, path_helper, 'id', 'desc', 0, '∞', false, {})
      expect(data[:json].items.count).to eq 15
      expect(data[:meta][:per_page]).to eq '∞'
    end
  end
end
