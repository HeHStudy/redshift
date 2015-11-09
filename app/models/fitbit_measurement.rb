require "zlib"

class FitbitMeasurement < Measurement

  CATEGORY_OPTIONS = [ "intraday", "daily" ]
  INTRADAY = 'intraday-1min'
  default_scope -> { where( type: "fitbit" ) }

  scope :weights,        lambda{ by_name("weight") }
  scope :weight_by_date, lambda{ |date| weights.by_date(date) }
  scope :activities,     lambda{ by_name("activities") }
  scope :trackers,       lambda{ by_name("tracker") }
  scope :daily,          lambda{ where( "name != ?", INTRADAY) }
  scope :intraday,       lambda{ where( name: INTRADAY ) }
  scope :sleep_times,    lambda{ where( name: Apis::Fitbit::SLEEP_TIME_SERIES) }

  validates_uniqueness_of :date, scope: [ :user_id, :name ], conditions: -> { where(name: INTRADAY) }
  validates_uniqueness_of :time, scope: [ :user_id, :name, :date ], conditions: -> { where(name: Apis::Fitbit::SLEEP_TIME_SERIES) }

  def find_attribute key_name
    JSON.parse( value_json )[key_name]
  end

  def decode_intraday_resource resource='steps'
    data = find_attribute resource
    return unless data
    z = Zlib::Inflate.inflate(Base64.strict_decode64 data)
    if resource == "calories" || resource == 'distance'
      z.unpack('F*')  # unpacks into array of floats
    else
      z.unpack('S*')   # unpacks into array of integers
    end
  end
end

