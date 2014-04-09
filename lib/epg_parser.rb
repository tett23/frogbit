# coding: utf-8

class EPGParser
  def initialize(name, program)
    @original_name = name
    @series_name = name
    @program = program
    @episode_number = nil
    @episode_name = nil
    @episode_data = episode_data()
    @event_id = event_id()

    convert_characters()
  end
  attr_reader :program, :name

  def convert_characters
    @original_name = Moji.zen_to_han(@original_name, Moji::ALNUM)
    @name = get_filename_entity()
    @program = @program.gsub(/\r\n?/, "\n").chomp.strip
    @program = Moji.zen_to_han(@program, Moji::ALNUM)
    @program = @program.gsub(/(＃|♯)/, '#')
  end

  def parse
    if @program.blank?
      puts @name+'のプログラム情報が空です'
      return program_hash()
    end

    if episode_data.blank?
      puts @name+'のプログラム情報はパース出来ません'

      name = "#{@name}_#{@event_id}.mp4"
      return program_hash(name: name)
    end

    filter!()

    process_program()
    process_name()
    @name = @name.gsub(/#\d+/, '').strip unless @name.blank?
    @episode_number = @episode_number.to_i unless @episode_number.blank?

    program_hash()
  end
  EPISODE_DATA_REGEX = /(?:#|第)(\d+)(?:話|回)?.*「(.+?)」/
  ONLY_EPISODE_NUMBER_REGEX = /^.*#(\d+)$/
  TITLE_FIRST_EPISODE_NUMBER = /^(.+?)\s*#(\d+)\s*「(.+)」.*$/
  TITLE_AFTER_EPISODE_NUMBER = /^(.+?)\s*「(.+)」\s*#(\d+).*$/

  def process_program
    # プログラムデータのパース
    if @episode_data.match(EPISODE_DATA_REGEX) # #12「hogehoge」みたいな形式
      matched = @episode_data.match(EPISODE_DATA_REGEX).to_a
      @episode_number = matched[1]
      @episode_name = matched[2]
    elsif @episode_data =~ ONLY_EPISODE_NUMBER_REGEX # サブタイなし、話数のみ
      @episode_name = nil
      @episode_number = @episode_data.gsub(ONLY_EPISODE_NUMBER_REGEX, '\1')
    elsif @episode_data.match(/「(.+?)」/) # 最初に現れたカギ括弧のなかをとる名前
      @episode_name = @episode_data.gsub(/^.*?「(.+?)」.*$/, '\1')
    else
      @episode_name = nil
    end
  end

  def process_name
    # タイトル（ファイル名にされているもの）のパース。同様のものはEPGの3行目に入っていることもある
    if @episode_data.match(EPISODE_DATA_REGEX) # #12「hogehoge」みたいな形式
      matched = @episode_data.match(EPISODE_DATA_REGEX).to_a
      @episode_number = matched[1]
      @episode_name = matched[2]
    elsif @name =~ TITLE_FIRST_EPISODE_NUMBER # タイトルにすべての情報が含まれている
      matched = @name.match(TITLE_FIRST_EPISODE_NUMBER).to_a
      matched.delete_at(0)
      @name, @episode_number, @episode_name = matched
    elsif @name =~  TITLE_AFTER_EPISODE_NUMBER # タイトルにすべての情報が含まれている
      matched = @name.match(TITLE_AFTER_EPISODE_NUMBER).to_a
      matched.delete_at(0)
      @name, @episode_name, @episode_number = matched
    elsif @name =~ ONLY_EPISODE_NUMBER_REGEX# タイトルに話数のみある
      @episode_number = @name.gsub(ONLY_EPISODE_NUMBER_REGEX, '\1')
    elsif @name =~ /^.+「(.+)」$/ # タイトルにサブタイのみある
      @episode_name = @name.gsub(/^.+「(.+)」$/, '\1')
      @name = @name.gsub(/^(.+)「.+」$/, '\1')
    end
  end

  def output_name
    # 可能なら名前#(episode_count)「(episode_name)」_(event_id)の形式に変換する。
    # 変換できない場合はある情報だけでやる
    "#{@name}#{@episode_number ? '#'+@episode_number.to_s : ''}#{@episode_name ? "「#{@episode_name}」" : ''}_#{@event_id}.mp4"
  end

  private
  def episode_data
    # 放送局によりかなり形式が異なる可能性あり。大体5行目に情報が入ってることが多い気がする
    episode = @program.split("\n")[4]
    @episode_data = episode
    @episode_data = '' if episode.blank?

    @episode_data
  end

  def event_id
    @program.split("\n").last.gsub(/^.*EventID:(\d+?)\(.+$/, '\1').strip
  end

  def filter!
    FilterRegexp.each do |filter|
      case filter.target
      when :description
        @episode_data.gsub!(filter.to_regexp, filter.alter)
      when :program
        @program.gsub!(filter.to_regexp, filter.alter)
      end
    end
  end

  def get_filename_entity()
    name = @original_name.gsub(/^\d+\-(.+)\.ts.*$/, '\1')
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


  def program_hash(options={})
    {
      name: @name,
      episode_name: @episode_name,
      episode_number: @episode_number,
      event_id: @event_id
    }.merge(options)
  end
end
