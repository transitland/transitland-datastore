class OnestopIdService
  include Singleton

  def self.find(onestop_id)
    OnestopId::PREFIX_TO_MODEL[onestop_id.split(OnestopId::COMPONENT_SEPARATOR)[0]].find_by_onestop_id(onestop_id)
  end

  def self.find!(onestop_id)
    OnestopId::PREFIX_TO_MODEL[onestop_id.split(OnestopId::COMPONENT_SEPARATOR)[0]].find_by_onestop_id!(onestop_id)
  end
end
