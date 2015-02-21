module DiffAgainstJson
  extend ActiveSupport::Concern

  included do

  end

  def diff_against(comparison)
    differences = {}
    if comparison.is_a? Stop
      # TODO: write this
    elsif comparison.is_a? Hash
      # TODO: write this
    else
      raise ArgumentError.new('not a supported comparison object.')
    end
  end
end
