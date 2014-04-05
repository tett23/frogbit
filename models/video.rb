# coding: utf-8

class Video
  include DataMapper::Resource

  property :id, Serial
  property :identification_code, String, :unique=>true
  property :event_id, String
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
  DISPORSABLE_SIZE = 1000 * 1000 * 250 # 250MB以上のファイルなら削除してもいい

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

    command = "sh ./drop_sd.sh '#{ts}' #{repaired_ts}"
    out = ''
    systemu(command, :out=>out)

    self.update(repaired_ts: repaired_ts)

    command
  end

  def exists_repair?
    repaired_path = repair_path()

    File.exists?(repaired_path)
  end

  def rm_repaired
    return unless exists_repair?

    FileUtils.rm(repair_path())
  end

  def self.search(keywords)
    keywords = keywords.strip.split(/\s/)
    return [] if keywords.size.zero?

    # LIKEをむりやりANDさせる
    a = keywords.map do |_|
      'program like ?'
    end.join(' and ')
    items = all(:conditions => [a, *(keywords.map {|k| "%#{k}%"})])

    video_ids = items.flatten.uniq.map do |v|
      v.id
    end

    all(id: video_ids, order: [:name, :id.desc])
  end

  def self.disporsable(size)
    identification_codes = Dir::entries($config[:input_dir]).map do |filename|
      next unless filename =~ REC_REGEX
      next filename if File.extname(filename) == '.ts'
    end.uniq.compact.map do |filename|
      TS.get_identification_code(filename)
    end

    disporsable_size = size.nil? ? Video::DISPORSABLE_SIZE : size.to_i
    condition = ({
      identification_code: identification_codes,
      is_encoded: true
    }.merge({:filesize.gt => disporsable_size}))

    Video.list(condition)
  end

  def destroy_ts
    FileUtils.rm(err_path) if File.exists?(err_path)
    FileUtils.rm(program_path) if File.exists?(program_path)

    if File.exists?(ts_path)
      FileUtils.rm(ts_path)
      true
    else
      false
    end
  end

  def has_sd?
    `avconv -i "#{ts_path}" 2>#{out_video_info_path}`
    video_info = `cat #{out_video_info_path} | grep Stream | grep 720`

    exists_sd = !!video_info.match(/Video: mpeg2video.+720/)
    FileUtils.rm(out_video_info_path) if File.exists?(out_video_info_path)

    exists_sd
  end

  private
  def repair_path
    "./tmp/#{self.identification_code}.ts"
  end

  def ts_path
    "#{$config[:input_dir]}/#{self.original_name}"
  end

  def err_path
    ts_path+'.err'
  end

  def program_path
    ts_path+'.program.txt'
  end

  def out_video_info_path
    "tmp/video_info_#{self.identification_code}"
  end
end
