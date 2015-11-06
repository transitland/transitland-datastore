module Faker
  module OnestopId
    def self.feed
      generate_unique_fake_onestop_id('f')
    end

    def self.stop
      generate_unique_fake_onestop_id('s')
    end

    def self.operator
      generate_unique_fake_onestop_id('o')
    end

    def self.route
      generate_unique_fake_onestop_id('r')
    end

    private

    def self.generate_unique_fake_onestop_id(entity_prefix)
      begin
        fake_onestop_id = "#{entity_prefix}-#{fake_geohash}-#{fake_name(entity_prefix)}"
      end until is_unique?(fake_onestop_id)
      fake_onestop_id
    end

    def self.is_unique?(onestop_id)
      is_unique = false
      begin
        ::OnestopId.find!(onestop_id)
      rescue ActiveRecord::RecordNotFound
        is_unique = true
      end
      is_unique
    end

    def self.fake_geohash
      geohash_base32 = '0123456789bcdefghjkmnpqrstuvwxyz'
      (2..rand(3..5)).map { |i| geohash_base32[SecureRandom.random_number(32)] }.join('')
    end

    def self.fake_name(entity_prefix)
      case entity_prefix
      when 's'
        ['CntrStn', 'RedSquare', 'FakeLand', 'MallOMerica'].sample
      when 'o'
        ['AlwaysLate', 'FailTrain', 'BestBus', 'BadBus', 'GitGoin'].sample
      when 'r'
        ['ECR', '522Rapid', 'NJudah'].sample
      when 'f'
        ['BART', 'ACTransit'].sample
      end
    end
  end
end
