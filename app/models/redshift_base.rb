class RedshiftBase < ActiveRecord::Base
  #Define your redshift db settings on config/database.yml
  establish_connection ActiveRecord::Base.configurations["redshift"]
  self.abstract_class = true
end
