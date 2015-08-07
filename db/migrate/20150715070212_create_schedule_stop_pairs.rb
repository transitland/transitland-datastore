class CreateScheduleStopPairs < ActiveRecord::Migration
  def change
    create_table :current_schedule_stop_pairs do |t|
      # Compound key
      t.references :origin, class_name: "Stop", index: { name: 'c_ssp_origin' }
      t.references :destination, class_name: "Stop", index: { name: 'c_ssp_destination' }
      t.references :route, index: { name: 'c_ssp_route' }
      t.string :trip, index: { name: 'c_ssp_trip' }

      # Changeset
      t.references :created_or_updated_in_changeset, index: { name: 'c_ssp_cu_in_changeset' }
      t.integer :version
      
      # Trip/edge data
      t.string :trip_headsign
      t.string :origin_arrival_time
      t.string :origin_departure_time
      t.string :destination_arrival_time
      t.string :destination_departure_time
      t.string :frequency_start_time
      t.string :frequency_end_time
      t.string :frequency_headway_seconds      
      t.hstore :tags
      
      # Calendar
      t.date :service_start_date, index: { name: 'c_ssp_service_start_date' }
      t.date :service_end_date, index: { name: 'c_ssp_service_end_date' }
      t.date :service_added_dates, array: true, default: []
      t.date :service_except_dates, array: true, default: []
      t.boolean :service_days_of_week, array: true, default: []
      
      t.timestamps null: false
    end

    create_table :old_schedule_stop_pairs do |t|
      # TODO: Specify index names to reduce table name length.
      t.references :origin, class_name: "Stop", index: { name: 'o_ssp_origin' }, polymorphic: true
      t.references :destination, class_name: "Stop", index: { name: 'o_ssp_destination' }, polymorphic: true
      t.references :route, index: { name: 'o_ssp_route'}, polymorphic: true
      t.string :trip, index: { name: 'o_ssp_trip' }

      t.references :current, index: true
      t.references :created_or_updated_in_changeset, index: { name: 'o_ssp_cu_in_changeset' }
      t.references :destroyed_in_changeset, index: { name: 'o_ssp_d_in_changeset' }
      t.integer :version

      t.string :trip_headsign
      t.string :origin_arrival_time
      t.string :origin_departure_time
      t.string :destination_arrival_time
      t.string :destination_departure_time
      t.string :frequency_start_time
      t.string :frequency_end_time
      t.string :frequency_headway_seconds
      t.hstore :tags

      t.date :service_start_date, index: { name: 'o_ssp_service_start_date' }
      t.date :service_end_date, index: { name: 'o_ssp_service_end_date' }
      t.date :service_added_dates, array: true, default: []
      t.date :service_except_dates, array: true, default: []
      t.boolean :service_days_of_week, array: true, default: []

      t.timestamps null: false
    end
  end
end
