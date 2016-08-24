describe AllowFiltering do
  context '.by_attribute_array' do
    before(:each) do
      @entity1 = create(:operator, name: 'Foo')
      @entity2 = create(:operator, name: 'FOO')
    end

    it 'filters case sensitive' do
      expect(
        AllowFiltering.by_attribute_array(Operator, {name: 'Foo'}, :name, true)
      ).to match_array([@entity1])
    end

    it 'filters case insensitive' do
      expect(
        AllowFiltering.by_attribute_array(Operator, {name: 'foo'}, :name, false)
      ).to match_array([@entity1, @entity2])
    end
  end
end
