class RedshiftBase < ActiveRecord::Base
  #Define your redshift db settings on config/database.yml
  establish_connection ActiveRecord::Base.configurations["redshift"]
  self.abstract_class = true

  def self.pg_connection
    self.connection.instance_eval{@connection}
  end

end
