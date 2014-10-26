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
      collection = instance_double("FakeModel", count: 3, offset: [1, 2, 3])
      expect(
        object.send(:paginated_json_collection, collection, path_helper, 0, 50)
      ).to eq({
        json: [1, 2, 3],
        meta: {
          total: 3,
          offset: 0,
          per_page: 50
        }
      })
    end

    it 'multiple pages' do
      collection = instance_double("FakeModel", count: 100, offset: [1, 2, 3])
      expect(
        object.send(:paginated_json_collection, collection, path_helper, 40, 40)
      ).to eq({
        json: [1, 2, 3],
        meta: {
          total: 100,
          offset: 40,
          per_page: 40,
          next: 'http://blah/offset=80',
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
