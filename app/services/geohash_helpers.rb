module GeohashHelpers
  GEOFACTORY = RGeo::Geographic.simple_mercator_factory
  BASESEQUENCE = '0123456789bcdefghjkmnpqrstuvwxyz'    

  def self.encode(geometry, precision=10)
    # Encode a RGeo point to a geohash.
    GeoHash.encode(geometry.lat, geometry.lon, precision)
  end
    
  def self.decode(geohash, decimals=5)
    # Decode a geohash to an RGeo point.
    p = GeoHash.decode(geohash, decimals)
    GEOFACTORY.point(p[1], p[0])
  end
  
  def self.decode_bbox(geohash)
    # Decode a geohash to an RGeo bounding box.
    p = GeoHash.decode_bbox(geohash)
    RGeo::Cartesian::BoundingBox.create_from_points(
      GEOFACTORY.point(p[0][1], p[0][0]),
      GEOFACTORY.point(p[1][1], p[1][0])
    )
  end
  
  def self.adjacent(geohash, direction)
    # Return the neighboring geohash in a given n,s,e,w direction.
    # Based on an MIT licensed implementation by Chris Veness from:
    #   http://www.movable-type.co.uk/scripts/geohash.html
    # Ported from Python implementation in mapzen-geohash.
    raise ArgumentError.new('Empty geohash') if geohash.blank?
    raise ArgumentError.new('Invalid direction') unless [:n,:s,:e,:w].include?(direction)
    neighbor = {
      n: [ 'p0r21436x8zb9dcf5h7kjnmqesgutwvy', 'bc01fg45238967deuvhjyznpkmstqrwx' ],
      s: [ '14365h7k9dcfesgujnmqp0r2twvyx8zb', '238967debc01fg45kmstqrwxuvhjyznp' ],
      e: [ 'bc01fg45238967deuvhjyznpkmstqrwx', 'p0r21436x8zb9dcf5h7kjnmqesgutwvy' ],
      w: [ '238967debc01fg45kmstqrwxuvhjyznp', '14365h7k9dcfesgujnmqp0r2twvyx8zb' ]
    }
    border = {
      n: [ 'prxz',     'bcfguvyz' ],
      s: [ '028b',     '0145hjnp' ],
      e: [ 'bcfguvyz', 'prxz'     ],
      w: [ '0145hjnp', '028b'     ]
    }
    last = geohash[-1]
    parent = geohash[0..-2]
    t = geohash.length % 2
    if (border[direction][t].include?(last) &! parent.empty?)
      parent = adjacent(parent, direction)
    end
    parent + BASESEQUENCE[neighbor[direction][t].index(last)]
  end
  
  def self.neighbors(geohash)
    {
      n:  adjacent(geohash, :n),
      ne: adjacent(adjacent(geohash, :n), :e),
      e:  adjacent(geohash, :e),
      se: adjacent(adjacent(geohash, :s), :e),
      s:  adjacent(geohash, :s),
      sw: adjacent(adjacent(geohash, :s), :w),
      w:  adjacent(geohash, :w),
      nw: adjacent(adjacent(geohash, :n), :w),
      c:  geohash
    }
  end

  def self.neighbors_bbox(geohash)
    # Return a bounding box for the geohash+neighbors.
    neighborhood = neighbors(geohash)
    RGeo::Cartesian::BoundingBox.create_from_points(
      decode_bbox(neighborhood[:ne]).max_point,
      decode_bbox(neighborhood[:sw]).min_point
    )
  end
  
  def self.centroid(geometries)
    # Simple geometric average of geometries
    GEOFACTORY.point(
      geometries.map { |x| x.lon }.sum / geometries.size,
      geometries.map { |x| x.lat }.sum / geometries.size,      
    )
  end
  
  def self.fit(geometries)
    # Fit a collection of points inside a geohash+neighbors
    start = encode(centroid(geometries))
    geohashes = geometries.map { |x| encode(x) }
    for i in 1..(start.length-1) do
      g = start[0,i]
      neighborhood = neighbors(g).values
      unbounded = geohashes.reject { |x| neighborhood.include?(x[0,i])}
      if !unbounded.empty?
        break
      end
    end
    g[0..-2]    
  end
    
end