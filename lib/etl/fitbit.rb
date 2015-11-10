require 'csv'
module Etl
  class Fitbit
    BUCKET = ENV['REDSHIFT_BUCKET']
    BATCH_SIZE = 1000
    TABLE = 'fitbit_intraday'
    COLUMNS = %w( measurement_id user_id date minute resource value )
    RESOURCE = 'steps'

    def self.prepare_aws_s3
      # setup AWS credentials
      Aws.config.update({
        region: ENV['AWS_REGION'],
        credentials: Aws::Credentials.new(
          ENV['AWS_ACCESS_KEY_ID'],
          ENV['AWS_SECRET_ACCESS_KEY']
        )
      })
    end

    def self.load_data_to_redshift
      db = RedshiftBase.pg_connection
      # load the data, specifying the order of the fields
      db.exec <<-EOS
        COPY #{TABLE} (#{COLUMNS.join(',')})
        FROM 's3://#{BUCKET}/#{TABLE}/data'
        CREDENTIALS 'aws_access_key_id=#{ENV['AWS_ACCESS_KEY_ID']};aws_secret_access_key=#{ENV['AWS_SECRET_ACCESS_KEY']}'
        CSV
        EMPTYASNULL
        GZIP
      EOS
    end

    def self.load
      self.transform_and_upload_to_s3
      self.load_data_to_redshift
      self.clean_up_s3_bucket
    end

    def self.clean_up_s3_bucket
      s3     = Aws::S3::Resource.new
      bucket = s3.bucket(BUCKET)
      bucket.clear!
    end

    # extract data to CSV files and uplaod to S3
    def self.transform_and_upload_to_s3
      self.prepare_aws_s3
      measurements = FitbitMeasurement.intraday.where("id > ?", RedshiftFitbitIntraday.latest_measurement_id )
      measurements = measurements.where("value_json NOT LIKE '%steps\":null%'")
      measurements.find_in_batches(batch_size: BATCH_SIZE).with_index do |group, batch|
        Tempfile.open(TABLE) do |f|
          Zlib::GzipWriter.open(f) do |gz|
            csv_string = CSV.generate do |csv|
              group.each do |record|
                puts "processing meas_id: #{record.id}"
                record.decode_intraday_resource.each_with_index do |val,i|
                  i+=1
                  next if val == 0
                  csv << [record.id, record.user_id, record.date.strftime("%Y-%m-%d"), i, RESOURCE, val.to_f]
                end
              end
            end
            gz.write csv_string
          end
          # upload to s3
          s3 = Aws::S3::Resource.new
          key = "#{TABLE}/data-#{batch}.gz"
          obj = s3.bucket(BUCKET).object(key)
          obj.upload_file(f)
          puts ">>> file uploaded to s3"
        end
      end
    end
  end
end
