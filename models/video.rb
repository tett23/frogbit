# coding: utf-8

class Video
  include DataMapper::Resource

  property :id, Serial
  property :identification_code, String, :unique=>true
  property :event_id, String, :unique=>true
  property :name, String, :required=>true
  property :output_name, String
  property :episode_name, String
  property :episode_number, Integer
  property :original_name, String
  property :saved_directory, String
  property :repaired_ts, String
  property :filesize, Integer
  property :extension, Enum[:ts, :mp4, :avi]
  property :is_encoded, Boolean, :default=>false
  property :is_watched, Boolean, :default=>false
  property :program, Text
  property :encode_log, Text
  property :recording_error, Text
  property :is_encodable, Boolean, :default=>true
  property :created_at, DateTime
  property :updated_at, DateTime

  belongs_to :series, :required=>false
  belongs_to :video_metadata, :required=>false

  PER_PAGE = 20

  def self.list(options={})
    default = {
      order: [:created_at.desc, :id.desc]
    }
    options = default.merge(options)

    all(options)
  end

  def self.detail(id, options={})
    first(:id=>id)
  end

  def exists_ts?
    ts_path = "#{$config[:input_dir]}/#{self.original_name}"

    File.exists?(ts_path)
  end

  def repair
    ts = "#{$config[:input_dir]}/#{self.original_name}"
    repaired_ts = "./tmp/#{self.identification_code}.ts"

    command = "python ./src/drop_sd.py '#{ts}' #{repaired_ts}"
    out = ''
    command_result = systemu(command, :out=>out)

    self.update(repaired_ts: repaired_ts)

    command
  end
end
