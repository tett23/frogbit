# coding: utf-8

class TS
  REGEX_GET_IDENTIFICATION_CODE = /\-.+$/
  def initialize(original_name)
    ext = File.extname(original_name)
    original_name = original_name.gsub(/^(\d+\-.+\.ts)/, '\1') if ext=='.err' || ext=='.txt'

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
    program = @program.gsub(/\r\n?/, "\n").chomp.strip
    name = @name

    if program.blank?
      puts name+'のプログラム情報が空です'
      return
    end

    event_id = program.split("\n").last.gsub(/^.*EventID:(\d+?)\(.+$/, '\1').strip
    episode_number = nil
    episode_name = nil

    # 放送局によりかなり形式が異なる可能性あり。大体5行目に情報が入ってることが多い気がする
    episode_data = program.split("\n")[4]
    if episode_data.blank?
      puts name+'のプログラム情報はパース出来ません'

      name = "#{name}_#{event_id}.mp4"
      return {
        name: name,
        episode_name: nil,
        episode_number: nil,
        event_id: event_id
      }
    end

    p name, episode_data
    FilterRegexp.each do |filter|
      case filter.target
      when :description
        episode_data.gsub!(filter.to_regexp, filter.alter)
      when :program
        program.gsub!(filter.to_regexp, filter.alter)
      end
    end
    p name, episode_data

    circled_numbers = '①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳'
    circled_numbers_regex = /[①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳]$/
    episode_data_regex = /[#|第](\d+)[話]?.*「(.+?)」/
    only_episode_number_regex = /^.*#(\d+)$/
    only_episode_name_regex = /^.*#{name}「(.+)」$/

    # プログラムデータのパース
    if episode_data.match(episode_data_regex) # #12「hogehoge」みたいな形式
      matched = episode_data.match(episode_data_regex).to_a
      episode_number = matched[1]
      episode_name = matched[2]
    elsif episode_data.match(circled_numbers_regex) # サブタイ(2)みたいなの
      circled_number = episode_data.match(circled_numbers_regex).to_a.first
      episode_number = circled_numbers.index(circled_number)+1
      episode_name = episode_data.gsub(/^(.+)[①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳]$/, '\1')
    elsif episode_data =~ only_episode_name_regex # サブタイのみ
      episode_number = episode_data.gsub(only_episode_name_regex, '\1')
    elsif episode_data =~ only_episode_number_regex # サブタイなし、話数のみ
      episode_number = episode_data.gsub(only_episode_number_regex, '\1')
    elsif episode_data.match(/「(.+?)」/) # 最初に現れたカギ括弧のなかをとる名前
      episode_name = episode_data.gsub(/^.*?「(.+?)」.*$/, '\1')
    else
      episode_name = nil
    end

    # タイトル（ファイル名にされているもの）のパース。同様のものはEPGの3行目に入っていることもある
    if name =~ /^(.+?)\s*「(.+)」\s*#(\d+).*$/ # タイトルにすべての情報が含まれている
      matched = name.match(/^(.+?)\s*「(.+)」\s*#(\d+).*$/).to_a
      matched.delete_at(0)
      name, episode_name, episode_number = matched
    elsif name =~ only_episode_number_regex # タイトルに話数のみある
      episode_number = name.gsub(only_episode_number_regex, '\1')
      name = name.gsub(/#\d+/, '')
    elsif name =~ /^.+「(.+)」$/ # タイトルにサブタイのみある
      episode_name = name.gsub(/^.+「(.+)」$/, '\1')
      name = name.gsub(/^(.+)「.+」$/, '\1')
    end

    # 可能なら名前#(episode_count)「(episode_name)」_(event_id)の形式に変換する。
    # 変換できない場合はある情報だけでやる
    name = "#{name}#{episode_number ? '#'+episode_number.to_s : ''}#{episode_name ? "「#{episode_name}」" : ''}_#{event_id}.mp4"

    {
      name: name,
      episode_name: episode_name,
      episode_number: episode_number,
      event_id: event_id
    }
  end
end
