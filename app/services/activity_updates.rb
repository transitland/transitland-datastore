class ActivityUpdates
  include Singleton

  def self.updates_since(since=24.hours.ago)
    updates = changesets_created(since) + changesets_updated(since) + changesets_applied(since) + feeds_imported(since) + feeds_versions_fetched(since)
    updates.sort_by { |update| update[:at_datetime] }.reverse
  end

  private

  def self.changesets_created(since)
    changesets = Changeset.where("created_at > ?", since).includes(:user)
    updates = changesets.map do |changeset|
      {
        id: "c-#{changeset.id}-created",
        entity_type: 'changeset',
        entity_id: changeset.id,
        entity_action: 'created',
        by_user_id: changeset.user.try(:id),
        note: "Changeset ##{changeset.id} created. Includes notes: #{changeset.notes}",
        at_datetime: changeset.created_at
      }
    end
    updates  || []
  end

  def self.changesets_updated(since)
    # exclude the creation and application of changesets
    changesets = Changeset.where{
      (updated_at > since) &
      (updated_at != created_at) &
      ((updated_at != applied_at) | (applied_at == nil))
    }.includes(:user)
    updates = changesets.map do |changeset|
      {
        id: "c-#{changeset.id}-updated",
        entity_type: 'changeset',
        entity_id: changeset.id,
        entity_action: 'updated',
        by_user_id: changeset.user.try(:id),
        note: "Changeset ##{changeset.id} updated. Includes notes: #{changeset.notes}",
        at_datetime: changeset.updated_at
      }
    end
    updates || []
  end

  def self.changesets_applied(since)
    changesets = Changeset.where("applied_at > ?", since).includes(:user)
    updates = changesets.map do |changeset|
      {
        id: "c-#{changeset.id}-applied",
        entity_type: 'changeset',
        entity_id: changeset.id,
        entity_action: 'applied',
        by_user_id: changeset.user.try(:id),
        note: "Changeset ##{changeset.id} applied. Includes notes: #{changeset.notes}",
        at_datetime: changeset.applied_at
      }
    end
    updates || []
  end

  def self.feeds_imported(since)
    feed_version_imports = FeedVersionImport.where("created_at > ?", since)
    updates = feed_version_imports.map do |feed_version_import|
      success_word = feed_version_import.success ? 'successfully' : 'unsuccessfully'
      note = "
        Feed #{feed_version_import.feed.onestop_id} version
        with SHA1 hash #{feed_version_import.feed_version.sha1}
        #{success_word} imported at level #{feed_version_import.import_level}
      ".squish
      {
        id: "fvi-#{feed_version_import.id}-created",
        entity_type: 'feed',
        entity_id: feed_version_import.feed.onestop_id,
        entity_action: 'imported',
        note: note,
        at_datetime: feed_version_import.created_at
      }
    end
    updates || []
  end

  def self.feeds_versions_fetched(since)
    feed_versions = FeedVersion.where("created_at > ?", since)
    updates = feed_versions.map do |feed_version|
      note = "
        New version of #{feed_version.feed.onestop_id} feed
        with SHA1 hash #{feed_version.sha1} fetched.
        Calendar runs from #{feed_version.earliest_calendar_date}
        to #{feed_version.latest_calendar_date}.
      ".squish
      {
        id: "fv-#{feed_version.sha1}-created",
        entity_type: 'feed',
        entity_id: feed_version.feed.onestop_id,
        entity_action: 'fetched',
        note: note,
        at_datetime: feed_version.created_at
      }
    end
    updates || []
  end
end
