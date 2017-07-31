# https://stackoverflow.com/questions/41855334/rails-change-primary-id-to-64-bit-bigint
class AlterScheduleStopPairIdToBigint < ActiveRecord::Migration
  def up
    execute('ALTER TABLE current_schedule_stop_pairs ALTER COLUMN id SET DATA TYPE BIGINT')
    execute('ALTER TABLE old_schedule_stop_pairs ALTER COLUMN id SET DATA TYPE BIGINT')
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
