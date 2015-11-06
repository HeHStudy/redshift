class Measurement < ActiveRecord::Base
  self.inheritance_column = :no_sti

  def data
    @data ||= JSON.parse(value_json, allow_nan: true) rescue {}
  end
end
