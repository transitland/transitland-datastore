class FakePaginationCollection
  def initialize(items)
    @items = items
    @offset = 0
    @limit = @items.size
  end
  def order(key)
    @items = @items.sort
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

  context 'paginated_json_collection' do
    it 'one page' do
      collection = FakePaginationCollection.new((0...10).to_a)
      expect(
        object.send(:paginated_json_collection, collection, path_helper, 0, 10, {})
      ).to eq({
        json: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        meta: {
          total: 10,
          offset: 0,
          per_page: 10
        }
      })
    end

    it 'multiple pages' do
      collection = FakePaginationCollection.new((0...10).to_a)
      expect(
        object.send(:paginated_json_collection, collection, path_helper, 4, 4, {})
      ).to eq({
        json: [4, 5, 6, 7],
        meta: {
          total: 10,
          offset: 4,
          per_page: 4,
          next: 'http://blah/offset=8',
          prev: 'http://blah/offset=0'
        }
      })
    end

    it 'applies default sort order' do
      collection = FakePaginationCollection.new((0...10).to_a.shuffle)
      expect(
        object.send(:paginated_json_collection, collection, path_helper, 4, 4, {})
      ).to eq({
        json: [4,5,6,7],
        meta: {
          total: 10,
          offset: 4,
          per_page: 4,
          next: 'http://blah/offset=8',
          prev: 'http://blah/offset=0'
        }
      })
    end
  end

  it 'is_there_a_next_page' do
    expect(object.send(:is_there_a_next_page?, 10, 0, 10)).to be false
    expect(object.send(:is_there_a_next_page?, 11, 0, 10)).to be true
    expect(object.send(:is_there_a_next_page?, 11, 11, 10)).to be false
  end

  it 'is_there_a_prev_page' do
    expect(object.send(:is_there_a_prev_page?, 10, 0, 10)).to be false
    expect(object.send(:is_there_a_prev_page?, 100, 11, 10)).to be true
  end

end
