# == Schema Information
#
# Table name: gtfs_stop_times
#
#  id                       :integer          not null, primary key
#  arrival_time             :integer          not null
#  departure_time           :integer          not null
#  stop_sequence            :integer          not null
#  stop_headsign            :string
#  pickup_type              :integer
#  drop_off_type            :integer
#  shape_dist_traveled      :float
#  timepoint                :integer
#  interpolated             :integer          default(0), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  feed_version_id          :integer          not null
#  trip_id                  :integer          not null
#  stop_id                  :integer          not null
#  destination_id           :integer
#  destination_arrival_time :integer
#
# Indexes
#
#  index_gtfs_stop_times_on_arrival_time              (arrival_time)
#  index_gtfs_stop_times_on_departure_time            (departure_time)
#  index_gtfs_stop_times_on_destination_arrival_time  (destination_arrival_time)
#  index_gtfs_stop_times_on_destination_id            (destination_id)
#  index_gtfs_stop_times_on_feed_version_id           (feed_version_id)
#  index_gtfs_stop_times_on_stop_id                   (stop_id)
#  index_gtfs_stop_times_on_trip_id                   (trip_id)
#  index_gtfs_stop_times_unique                       (feed_version_id,trip_id,stop_sequence) UNIQUE
#

def display_trip(stop_times)
  stop_times.each do |st|
    puts "stop_sequence #{st.stop_sequence} stop_id #{st.stop_id} #{st.stop.stop_name} arrival_time #{st.arrival_time} departure_time #{st.departure_time}"
  end
end

RSpec.describe GTFSStopTime, type: :model do
    context 'interpolate_stop_times' do
      it 'test' do
        fv = load_gtfs_fixture('gtfs_bart_limited.json')
        # trip = GTFSTrip.where(trip_id: '01SFO10').first
        GTFSTrip.where('').each do |trip|
          sts = GTFSStopTime.where(trip: trip).to_a.sort_by { |st| st.stop_sequence }
          times1 = sts.map(&:departure_time)

          sts[1...sts.size-1].each { |st| st.arrival_time = nil; st.departure_time = nil }
          ActiveRecord::Base.logger = Logger.new(STDOUT)
          ActiveRecord::Base.logger.level = Logger::DEBUG
          puts "shape_id: #{trip.shape_id}"
          sts = GTFSStopTimeInterpolater.interpolate_stop_times(sts, trip.shape_id)

          times2 = sts.map(&:departure_time)
          times1.zip(times2).each do |a,b|
            puts "#{a} - #{b} = #{a - b}"
          end
        end
      end
    end
end  
