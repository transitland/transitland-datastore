describe OperatorRouteStopRelationship do
  context 'resolution #1: operator <-> route' do
    before(:each) do
      @stop = create(:stop)
      @operator = create(:operator)
      @operator_route_stop_relationship1 = OperatorRouteStopRelationship.new({
        operator_onestop_id: @operator.onestop_id,
        stop_onestop_id: @stop.onestop_id,
        does_service_exist: true
      })
      @changeset1 = create(:changeset)
    end

    it 'should be able to create an OperatorServingStop when none exists already' do
      @operator_route_stop_relationship1.apply_change(in_changeset: @changeset1)
      expect(@stop.operators).to include @operator
      expect(@changeset1.operators_serving_stop_created_or_updated).to include OperatorServingStop.first
    end

    it 'should be able to delete an OperatorServingStop when one already exists' do
      @operator_route_stop_relationship1.apply_change(in_changeset: @changeset1)
      operator_route_stop_relationship2 = OperatorRouteStopRelationship.new({
        operator_onestop_id: @operator.onestop_id,
        stop_onestop_id: @stop.onestop_id,
        does_service_exist: false
      })
      changeset2 = create(:changeset)
      expect(OldOperatorServingStop.count).to eq 0
      operator_route_stop_relationship2.apply_change(in_changeset: changeset2)
      expect(@stop.operators).to_not include @operator
      expect(OldOperatorServingStop.count).to eq 1
      expect(changeset2.operators_serving_stop_destroyed).to include OldOperatorServingStop.first
    end

    it "should be agreeable when trying to delete an OperatorServingStop that doesn't exist" do
      operator_route_stop_relationship = OperatorRouteStopRelationship.new({
        operator_onestop_id: @operator.onestop_id,
        stop_onestop_id: @stop.onestop_id,
        does_service_exist: false
      })
      expect(OldOperatorServingStop.count).to eq 0
      expect(OperatorServingStop.count).to eq 0
      operator_route_stop_relationship.apply_change(in_changeset: create(:changeset))
      expect(OldOperatorServingStop.count).to eq 0
      expect(OperatorServingStop.count).to eq 0
    end
  end
end
