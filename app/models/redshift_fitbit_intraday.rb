class RedshiftFitbitIntraday < RedshiftBase
  self.table_name = :fitbit_intraday

  def self.latest_measurement_id
     self.maximum(:measurement_id)
  end
end
