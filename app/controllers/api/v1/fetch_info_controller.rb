class Api::V1::FetchInfoController < Api::V1::BaseApiController

	def index
		url = params[:url]
		raise Exception.new('invalid URL') unless url
		
		file = Tempfile.new('test.zip', Dir.tmpdir, 'wb+')
		file.binmode
		begin
			response = Faraday.get(url)
			file.write(response.body)
			file.close
			operators = gtfs_create_operators(file.path)
		ensure
			file.close
			file.unlink
		end

		render json: {url: url, operators: operators}
	end

	private
	
	def gtfs_create_operators(filename)
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

		operators

	end
end
