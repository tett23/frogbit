# coding: utf-8

class TS
  REGEX_GET_IDENTIFICATION_CODE = /\-.+$/
  def initialize(original_name)
    ext = File.extname(original_name)
    original_name = original_name.gsub(/^(\d+\-.+\.ts)/, '\1') if ext=='.err' || ext=='.txt'

    @original_name = original_name
    @name = get_filename_entity(original_name)
    @series_name = @name
    @identification_code = TS.get_identification_code(original_name)
    @ext = :ts
    @is_watched = false
    @is_encoded = false
    set_attribute(parse_name())
  end

  attr_reader :original_name, :name, :ext, :identification_code, :is_subtitle, :is_digital, :error, :program

  def add_program(program_file)
    path = "#{$config[:input_dir]}/#{program_file}"
    program = open(path).read.encode('utf-8', 'sjis')
    program = program.gsub(/(＃|♯)/, '#')

    @program = Moji.zen_to_han(program, Moji::ALNUM)

    parsed_data = parse_epg()
    return @program if parsed_data.nil?
    @output_name = parsed_data[:name]
    @episode_name = parsed_data[:episode_name]
    @episode_number = parsed_data[:episode_number]
    @event_id = parsed_data[:event_id]

    @program
  end

  def add_error(error_file)
    path = "#{$config[:input_dir]}/#{error_file}"
    error = open(path).read.encode('utf-8', 'sjis')

    @error = Moji.zen_to_han(error, Moji::ALNUM)
  end

  def self.get_identification_code(filename)
    filename.gsub(REGEX_GET_IDENTIFICATION_CODE, '')
  end

  def to_hash(format=nil)
    case format
    when :video
      {
        identification_code: @identification_code,
        event_id: @event_id,
        name: @name,
        output_name: @output_name,
        episode_name: @episode_name,
        episode_number: @episode_number,
        original_name: @original_name,
        recording_error: @error,
        program: @program,
        saved_directory: @saved_directory,
        extension: @ext,
        is_encoded: @is_encoded,
        is_watched: @is_watched
      }
    when :video_metadata
      {
        is_subtitle: @is_subtitle,
        is_digital: @is_digital
      }
    when :series
      {
        name: @series_name
      }
    else
      {
        identification_code: @identification_code,
        name: @name,
        original_name: @original_name,
        recording_error: @error,
        program: @program,
        saved_directory: @saved_directory,
        extension: @ext,
        episode: @episode,
        is_encoded: @is_encoded,
        is_watched: @is_watched,
        is_subtitle: @is_subtitle,
        is_digital: @is_digital,
        series_name: @series_name,
        period: @period
      }
    end
  end
  alias_method :to_h, :to_hash

  def self.get_ext(filename)
    raise 'TS::get_ext: ts情報を含まないファイル名' unless filename.match(/\.ts/)

    filename.gsub(/^.+\.(ts.*)$/, '\1').to_sym
  end

  private
  def get_filename_entity(video_file)
    name = video_file.gsub(/^\d+\-(.+)\.ts.*$/, '\1')
    if name.match(/\[/)
      name = name.gsub(/^(.+?)\[.+/, '\1')
    end

    name = Moji.zen_to_han(name, Moji::ALNUM)
    name = name.gsub(/　/, ' ')
    name = name.gsub(/(＃|♯)/, '#')
    name = name.gsub(/＜.+＞/, '')

    FilterRegexp.list(target: :filename).each do |filter|
      name.gsub!(filter.to_regexp, filter.alter)
    end

    name
  end

  def parse_name
    @original_name.split(/\[(.)\]/).delete_if do |s|
      s.blank?
    end
  end

  def set_attribute(attributes)
    attributes.each do |attribute|
      case attribute
      when '字'
        @is_subtitle = true
      when 'デ'
        @is_digital = true
      when '再'
      when 'Ｓ'
      when '解'
      end
    end
  end

  def parse_epg
    epg_parser = EPGParser.new(@name, @program)
    parsed = epg_parser.parse()
    @series_name = epg_parser.name

    {
      name: epg_parser.output_name,
      episode_name: parsed[:episode_name],
      episode_number: parsed[:episode_number],
      event_id: parsed[:event_id]
    }
  end
end
