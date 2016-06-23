class StopEgress < Stop
  current_tracked_by_changeset({
    kind_of_model_tracked: :onestop_entity,
    virtual_attributes: [
      :served_by,
      :not_served_by,
      :identified_by,
      :not_identified_by,
      :parent_stop_onestop_id,
      :includes_stop_transfers,
      :does_not_include_stop_transfers
    ],
    protected_attributes: [
      :identifiers,
      :last_conflated_at,
      :type
    ]
  })
  belongs_to :parent_stop, class_name: 'Stop'
  validates :parent_stop, presence: true
  def parent_stop_onestop_id
    if self.parent_stop
      self.parent_stop.onestop_id
    end
  end
  def parent_stop_onestop_id=(value)
    self.parent_stop = Stop.find_by_onestop_id!(value)
  end
end

class OldStopEgress < OldStop
end
