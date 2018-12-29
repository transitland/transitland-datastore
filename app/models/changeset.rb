# == Schema Information
#
# Table name: changesets
#
#  id              :integer          not null, primary key
#  notes           :text
#  applied         :boolean
#  applied_at      :datetime
#  created_at      :datetime
#  updated_at      :datetime
#  user_id         :integer
#  feed_id         :integer
#  feed_version_id :integer
#
# Indexes
#
#  index_changesets_on_feed_id          (feed_id)
#  index_changesets_on_feed_version_id  (feed_version_id)
#  index_changesets_on_user_id          (user_id)
#

class Changeset < ActiveRecord::Base
  class Error < StandardError
    attr_accessor :changeset, :message, :backtrace, :payload

    def initialize(changeset: nil, payload: {}, message: '', backtrace: [])
      @changeset = changeset
      @payload = payload
      @message = message
      @backtrace = backtrace
    end

    def to_s
      "Changeset::Error #{@message}"
    end
  end

  CHANGE_PAYLOAD_MAX_ENTITIES = Figaro.env.feed_eater_change_payload_max_entities.try(:to_i) || 1_000

  include CanBeSerializedToCsv

  has_many :feeds_created_or_updated, class_name: 'Feed', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :feeds_destroyed, class_name: 'OldFeed', foreign_key: 'destroyed_in_changeset_id'

  has_many :operators_in_feed_created_or_updated, class_name: 'OperatorInFeed', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :operators_in_feed_destroyed, class_name: 'OldOperatorInFeed', foreign_key: 'destroyed_in_changeset_id'

  has_many :stops_created_or_updated, class_name: 'Stop', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :stops_destroyed, class_name: 'OldStop', foreign_key: 'destroyed_in_changeset_id'

  has_many :stop_platforms_created_or_updated, class_name: 'StopPlatform', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :stop_platforms_destroyed, class_name: 'StopPlatform', foreign_key: 'destroyed_in_changeset_id'

  has_many :operators_created_or_updated, class_name: 'Operator', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :operators_destroyed, class_name: 'OldOperator', foreign_key: 'destroyed_in_changeset_id'

  has_many :routes_created_or_updated, class_name: 'Route', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :routes_destroyed, class_name: 'OldRoute', foreign_key: 'destroyed_in_changeset_id'

  has_many :operators_serving_stop_created_or_updated, class_name: 'OperatorServingStop', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :operators_serving_stop_destroyed, class_name: 'OldOperatorServingStop', foreign_key: 'destroyed_in_changeset_id'

  has_many :routes_serving_stop_created_or_updated, class_name: 'RouteServingStop', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :routes_serving_stop_destroyed, class_name: 'OldRouteServingStop', foreign_key: 'destroyed_in_changeset_id'

  has_many :change_payloads, -> { order "created_at ASC" }, dependent: :destroy

  has_many :schedule_stop_pairs_created_or_updated, class_name: 'ScheduleStopPair', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :schedule_stop_pairs_destroyed, class_name: 'OldScheduleStopPair', foreign_key: 'destroyed_in_changeset_id'

  has_many :route_stop_patterns_created_or_updated, class_name: 'RouteStopPattern', foreign_key: 'created_or_updated_in_changeset_id'
  has_many :route_stop_patterns_destroyed, class_name: 'OldRouteStopPattern', foreign_key: 'destroyed_in_changeset_id'

  belongs_to :user, autosave: true
  belongs_to :imported_from_feed, class_name: 'Feed', foreign_key: 'feed_id'
  belongs_to :imported_from_feed_version, class_name: 'FeedVersion', foreign_key: 'feed_version_id'

  def set_user_by_params(user_params)
    self.user = User.find_or_initialize_by(email: user_params[:email].downcase)
    self.user.update_attributes(user_params)
    self.user.user_type ||= nil # for some reason, Enumerize needs to see a value
  end

  after_initialize :set_default_values
  after_create :creation_email

  def entities_created_or_updated(&block)
    # Pass &block to find_each for each kind of entity.
    feeds_created_or_updated.find_each(&block)
    operators_in_feed_created_or_updated.find_each(&block)
    stops_created_or_updated.find_each(&block)
    operators_created_or_updated.find_each(&block)
    routes_created_or_updated.find_each(&block)
    route_stop_patterns_created_or_updated.find_each(&block)
  end

  def relations_created_or_updated(&block)
    operators_serving_stop_created_or_updated.find_each(&block)
    routes_serving_stop_created_or_updated.find_each(&block)
  end

  def entities_destroyed(&block)
    feeds_destroyed.find_each(&block)
    operators_destroyed.find_each(&block)
    stops_destroyed.find_each(&block)
    operators_destroyed.find_each(&block)
    routes_destroyed.find_each(&block)
    route_stop_patterns_destroyed.find_each(&block)
  end

  def relations_destroyed(&block)
    operators_serving_stop_destroyed.find_each(&block)
    routes_serving_stop_destroyed.find_each(&block)
  end

  def trial_succeeds?
    trial_succeeds = false
    issues = []
    Changeset.transaction do
      begin
        trial_succeeds, issues = apply!
      rescue Exception => e
        raise ActiveRecord::Rollback
      else
        raise ActiveRecord::Rollback
      end
    end
    self.reload
    return trial_succeeds, issues
  end

  def create_change_payloads(entities)
    entities.each_slice(CHANGE_PAYLOAD_MAX_ENTITIES).each do |chunk|
      changes = chunk.map do |entity|
        {
          :action => :createUpdate,
          entity.class.name.camelize(:lower) => entity.as_change(sticky: sticky?).as_json.compact
        }
      end
      payload = {changes: changes}
      begin
        change_payload = self.change_payloads.create!(payload: payload)
      rescue StandardError => e
        fail Changeset::Error.new(
          changeset: self,
          payload: payload,
          message: e.message,
          backtrace: e.backtrace
        )
      end
    end
  end

  def destroy_all_change_payloads
    # Destroy change payloads
    change_payloads.destroy_all
  end

  def import?
    !!self.imported_from_feed && !!self.imported_from_feed_version
  end

  def sticky?
    import? && self.imported_from_feed.feed_version_imports.size > 1
  end

  def issues_unresolved(resolving_issues, changeset_issues)
    # changeset does not contain entities matching any resolving issue entities
    unresolved_issues = Set.new(resolving_issues.select { |issue|
      unless issue.entities_with_issues.empty?
        issue.entities_with_issues.map(&:entity).none? { |issue_entity|
          eqls = []
          entities_created_or_updated { |entity| eqls << issue_entity.eql?(entity) }
          eqls.any?
        }
      end
    })
    # changeset does not resolve issue (creates the same issue in quality checks)
    unresolved_issues.merge(changeset_issues.map { |c| resolving_issues.map { |r| r if c.equivalent?(r) } }.flatten.compact)
  end

  def check_quality
    gqc = QualityCheck::GeometryQualityCheck.new(changeset: self)
    shqc = QualityCheck::StationHierarchyQualityCheck.new(changeset: self)
    issues = []
    issues += gqc.check
    issues += shqc.check
    issues
  end

  def update_computed_attributes
    old_issues_to_deprecate = Set.new
    geometry_updater = UpdateComputedAttributes::GeometryUpdateComputedAttributes.new(changeset: self)
    old_geometry_issues_to_deprecate, sizes = geometry_updater.update_computed_attributes
    old_issues_to_deprecate.merge(old_geometry_issues_to_deprecate)
  end

  def cycle_issues(issues_changeset_is_resolving, new_issues_created_by_changeset, old_issues_to_deprecate)
    # check if a changeset's specified issuesResolved, if any, are actually resolved.
    unresolved_issues = issues_unresolved(issues_changeset_is_resolving, new_issues_created_by_changeset)
    if (unresolved_issues.empty?)
      issues_changeset_is_resolving.each { |issue| issue.update!({ open: false, resolved_by_changeset: self}) }

      new_issues_created_by_changeset.each(&:save!)

      # need to make sure the right instances of the resolving issues -
      # those containing open=false and resolved_by_changeset - are added
      # to old_issues_to_deprecate so they are logged as "resolved" during deprecation,
      # before the transaction is complete.
      old_issues_to_deprecate.keep_if { |i|
          !issues_changeset_is_resolving.map(&:id).include?(i.id)
        }.merge(issues_changeset_is_resolving)
        .each(&:deprecate)
    else
      message = unresolved_issues.map { |issue| "Issue #{issue.id} was not resolved." }.join(" ")
      log "Error applying Changeset #{self.id}: #{message}", :error
      raise Changeset::Error.new(changeset: self, message: message)
    end
  end

  def post_quality_check_updates
    self.route_stop_patterns_created_or_updated.each do |rsp|
      rsp_dist_issues = Issue.issues_of_entity(rsp).where(issue_type: 'distance_calculation_inaccurate').to_a
      if rsp_dist_issues.any?
        if rsp.geometry_source.eql?("shapes_txt_with_dist_traveled")
          # shape_dist_traveled values may be faulty. So trying the TL algorithm here.
          Geometry::TLDistances.new(rsp).calculate_distances
          qc = QualityCheck::GeometryQualityCheck.new(changeset: self)
          rsp.stop_pattern.each_index do |i|
            qc.stop_distances_accuracy(rsp, i)
          end
          rsp_dist_issues.each(&:deprecate)
          rsp_dist_issues = qc.issues
          rsp_dist_issues.each(&:save!)
          rsp.geometry_source = :shapes_txt
        end
        if rsp_dist_issues.any?
          rsp.stop_distances = Array.new(rsp.stop_pattern.size)
        end
        rsp.update_making_history(changeset: self)
        unless import?
          rsp.ordered_ssp_trip_chunks { |trip_chunk|
            trip_chunk.each_with_index do |ssp, i|
              ssp.update_column(:origin_dist_traveled, rsp.stop_distances[i])
              ssp.update_column(:destination_dist_traveled, rsp.stop_distances[i+1])
            end
          }
        end
      end
    end
  end

  def apply!
    fail Changeset::Error.new(changeset: self, message: 'has already been applied.') if applied
    new_issues_created_by_changeset = []
    old_issues_to_deprecate = Set.new

    Changeset.transaction do
      begin
        # Apply changes
        change_payloads.each do |change_payload|
          change_payload.apply_change
        end

        # Apply associations
        change_payloads.each do |change_payload|
          change_payload.apply_associations
        end

        # Collect issues
        issues_changeset_is_resolving = []
        change_payloads.each do |change_payload|
          payload_issues_changeset_is_resolving, payload_old_issues_to_deprecate = change_payload.resolving_and_deprecating_issues
          issues_changeset_is_resolving += payload_issues_changeset_is_resolving
          old_issues_to_deprecate.merge(payload_old_issues_to_deprecate)
        end

        # Mark as applied
        self.update(applied: true, applied_at: Time.now)

        # Update attributes that derive from attributes between models
        # This needs to be done before quality checks. Only on import.
        unless import?
          computed_attrs_old_issues_to_deprecate, sizes = update_computed_attributes
          old_issues_to_deprecate.merge(computed_attrs_old_issues_to_deprecate)
        end

        # Check for new issues on this changeset
        new_issues_created_by_changeset = check_quality

        # save new issues; deprecate old issues; resolve changeset-specified issues
        cycle_issues(issues_changeset_is_resolving, new_issues_created_by_changeset, old_issues_to_deprecate)

        # modify entity attribute values based on quality issues found
        post_quality_check_updates

      rescue StandardError => error
        log "Error applying Changeset #{self.id}: #{error.message}", :error
        log error.backtrace, :error
        raise Changeset::Error.new(changeset: self, message: error.message, backtrace: error.backtrace)
      end
    end

    unless Figaro.env.send_changeset_emails_to_users.presence == 'false'
      if self.user && self.user.email.present? && !self.user.admin
        ChangesetMailer.delay.application(self.id)
      end
    end
    # Now that the transaction is complete and has been committed,
    # we can do some async tasks like conflate stops with OSM...
    if Figaro.env.auto_conflate_stops_with_osm.present? &&
       Figaro.env.auto_conflate_stops_with_osm == 'true' &&
       self.stops_created_or_updated.count > 0
      StopConflateWorker.perform_async(self.stops_created_or_updated.map(&:id))
    end
    # ...and fetching any new feeds
    if Figaro.env.auto_fetch_feed_version.presence == 'true'
      FeedFetcherService.fetch_these_feeds_async(self.feeds_created_or_updated)
    end
    return true, new_issues_created_by_changeset
  end

  def revert!
    if applied
      # TODO: write it
      raise Changeset::Error.new(changeset: self, message: "cannot revert. This functionality doesn't exist yet.")
    else
      raise Changeset::Error.new(changeset: self, message: 'cannot revert. This changeset has not been applied yet.')
    end
  end

  def bounding_box
    # TODO: write it
  end

  def payload=(changeset)
    change_payloads.build payload: changeset
  end

  private

  def set_default_values
    if self.new_record?
      self.applied ||= false
    end
  end

  def creation_email
    unless Figaro.env.send_changeset_emails_to_users.presence == 'false'
      if self.user && self.user.email.present? && !self.user.admin
        ChangesetMailer.delay.creation(self.id)
      end
    end
  end

end
