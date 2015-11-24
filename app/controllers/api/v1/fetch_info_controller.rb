class Api::V1::FetchInfoController < Api::V1::BaseApiController

	def index
		url = params[:url]
		filename = Rails.root.join('spec/support/example_gtfs_archives/f-9q9-caltrain.zip')
		gtfs = GTFS::Source.build(filename, {strict: false})
		gtfs.load_graph
		operators = {}

		gtfs.agencies.each do |agency|
			stops = Set.new
			gtfs.children(agency).each do |route|
				gtfs.children(route).each do |trip|
					gtfs.children(trip).each do |stop|
						stops.add(stop)
					end
				end
			end
			stops = stops.map { |stop| Stop.from_gtfs(stop) }
			operator = Operator.from_gtfs(agency, stops)
			operators[operator.onestop_id] = operator
			# TODO: Pass through Operator serializer
		end

		render json: {url: url, operators: operators}
	end
end
