# coding: utf-8

class TS
  REGEX_GET_IDENTIFICATION_CODE = /\-.+$/
  def initialize(original_name)
    @original_name = original_name
    @name = get_filename_entity(original_name)
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

    @program = Moji.zen_to_han(program, Moji::ALNUM)
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
        name: @name,
        original_name: @original_name,
        recording_error: @error,
        program: @program,
        saved_directory: @saved_directory,
        extension: @ext,
        episode: @episode,
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
        series_name: @series_name,
        period: @period
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
end
