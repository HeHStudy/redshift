#See: http://docs.aws.amazon.com/redshift/latest/dg/c_Supported_data_types.html

namespace :create_schemas do
  desc 'sample of creating a new table on the warehouse'
  task :events => :environment do |task|
    connection = RedshiftBase.pg_connection
    connection.exec <<-EOS
      CREATE TABLE events (
        id BIGINT SORTKEY NOT NULL,
        received_at_raw VARCHAR(25) NOT NULL,
        generated_at_raw VARCHAR(25) NOT NULL,
        source_id INT NOT NULL,
        source_name VARCHAR(128) ENCODE Text32k,
        source_ip VARCHAR(15) NOT NULL ENCODE Text32k,
        facility VARCHAR(8) NOT NULL ENCODE Text255,
        severity VARCHAR(9) NOT NULL ENCODE Text255,
        program VARCHAR(64) ENCODE Text32k,
        message VARCHAR(8192) DEFAULT NULL,
        PRIMARY KEY(id)
      )
      DISTSTYLE even;
    EOS
  end
end
