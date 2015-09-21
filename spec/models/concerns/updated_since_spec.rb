describe UpdatedSince do
  it 'updated since' do
    expect_0 = DateTime.new(2016, 01, 01)
    expect_1 = DateTime.new(2015, 01, 01)
    expect_2 = DateTime.new(2014, 01, 01)
    expect_all = DateTime.new(2000, 01, 01)
    create(:stop, updated_at: expect_1)
    create(:stop, updated_at: expect_2)
    expect(Stop.updated_since(expect_all).count).to eq(2)   
    expect(Stop.updated_since(expect_2).count).to eq(2)    
    expect(Stop.updated_since(expect_1).count).to eq(1)
    expect(Stop.updated_since(expect_0).count).to eq(0)
  end
end
