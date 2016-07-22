# BigDecimal: JSON as Float (monkey patch)
# http://stackoverflow.com/questions/6128794/rails-json-serialization-of-decimal-adds-quotes
class BigDecimal
  def as_json(options = nil)
    self.to_f
  end
end
