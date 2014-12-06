class StopIdentifier < ActiveRecord::Base
  belongs_to :stop
end


class CreateGenericIdentifier < ActiveRecord::Migration
  def change
    create_table :identifiers do |t|
      t.references :identified_entity, null: false, polymorphic: true
      t.string :identifier
      t.hstore :tags
      t.timestamps
    end
    add_index :identifiers, :identified_entity_id
    add_index :identifiers, [:identified_entity_id, :identified_entity_type], name: 'identified_entity'

    StopIdentifier.find_each do |stop_identifier|
      Identifier.create(
        identified_entity: stop_identifier.stop,
        identifier: stop_identifier.identifier,
        tags: stop_identifier.tags
      )
    end

    drop_table :stop_identifiers
  end
end
