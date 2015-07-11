# == Schema Information
#
# Table name: changesets
#
#  id         :integer          not null, primary key
#  notes      :text
#  applied    :boolean
#  applied_at :datetime
#  created_at :datetime
#  updated_at :datetime
#

class Changeset < ActiveRecord::Base
  class Error < StandardError
    attr_accessor :changeset, :message, :backtrace

    def initialize(changeset, message, backtrace=[])
      @changeset = changeset
      @message = message
      @backtrace = backtrace
    end
  end

  PER_PAGE = 50

  include CanBeSerializedToCsv

  has_many :stops_created_or_updated, class_name: 'Stop', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :stops_destroyed, class_name: 'OldStop', foreign_key: 'destroyed_in_changeset_id'

  has_many :operators_created_or_updated, class_name: 'Operator', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :operators_destroyed, class_name: 'OldOperator', foreign_key: 'destroyed_in_changeset_id'

  has_many :routes_created_or_updated, class_name: 'Route', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :routes_destroyed, class_name: 'OldRoute', foreign_key: 'destroyed_in_changeset_id'

  has_many :operators_serving_stop_created_or_updated, class_name: 'OperatorServingStop', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :operators_serving_stop_destroyed, class_name: 'OldOperatorServingStop', foreign_key: 'destroyed_in_changeset_id'

  has_many :routes_serving_stop_created_or_updated, class_name: 'RouteServingStop', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :routes_serving_stop_destroyed, class_name: 'OldRouteServingStop', foreign_key: 'destroyed_in_changeset_id'

  has_many :change_payloads, dependent: :destroy

  after_initialize :set_default_values

  def entities_created_or_updated
    # NOTE: this is probably evaluating the SQL queries, rather than merging together ARel relations
    # in Rails 5, there will be an ActiveRecord::Relation.or() operator to use instead here
    (
      stops_created_or_updated +
      operators_created_or_updated +
      routes_created_or_updated +
      operators_serving_stop_created_or_updated +
      routes_serving_stop_created_or_updated
    )
  end

  def entities_destroyed
    (
      stops_destroyed +
      operators_destroyed +
      routes_destroyed +
      operators_serving_stop_destroyed +
      routes_serving_stop_destroyed
    )
  end

  def trial_succeeds?
    trial_succeeds = false
    Changeset.transaction do
      begin
        apply!
      rescue Exception => e
        raise ActiveRecord::Rollback
      else
        trial_succeeds = true
        raise ActiveRecord::Rollback
      end
    end
    self.reload
    trial_succeeds
  end

  def apply!
    if applied
      raise Changeset::Error.new(self, 'has already been applied.')
    else
      Changeset.transaction do
        begin
          change_payloads.each do |change_payload|
            change_payload.apply!
          end
          self.update(applied: true, applied_at: Time.now)
          # Destroy change payloads
          change_payloads.destroy_all
        rescue
          raise Changeset::Error.new(self, $!.message, $!.backtrace)
        end
      end
      # Now that the transaction is complete and has been committed,
      # we can do some async tasks like conflate stops with OSM.
      if Figaro.env.auto_conflate_stops_with_osm.present? &&
         Figaro.env.auto_conflate_stops_with_osm == 'true' &&
         self.stops_created_or_updated.count > 0
        ConflateStopsWithOsmWorker.perform_async(self.stops_created_or_updated.map(&:id))
      end
      true
    end
  end

  def revert!
    if applied
      # TODO: write it
      raise Changeset::Error.new(self, "cannot revert. This functionality doesn't exist yet.")
    else
      raise Changeset::Error.new(self, 'cannot revert. This changeset has not been applied yet.')
    end
  end

  def bounding_box
    # TODO: write it
  end

  def append(changeset)
    change_payloads.build payload: changeset
  end

  def payload=(changeset)
    append changeset
  end

  private

  def set_default_values
    if self.new_record?
      self.applied ||= false
    end
  end

end
