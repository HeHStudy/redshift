#See: http://docs.aws.amazon.com/redshift/latest/dg/c_Supported_data_types.html

namespace :create_schemas do
  desc 'create fitbit_intraday table'
  task :fitbit_intraday => :environment do |task|
    connection = RedshiftBase.pg_connection
    connection.exec <<-EOS
      CREATE TABLE fitbit_intraday (
        id BIGINT SORTKEY NOT NULL,
        user_id INT NOT NULL,
        date date NOT NULL,
        minute INT NOT NULL,
        resource VARCHAR(100) NOT NULL,
        value decimal(8,2) NOT NULL,
        PRIMARY KEY(id)
      )
      DISTSTYLE even;
    EOS
  end
end
