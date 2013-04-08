# coding: utf-8

namespace :debug do
  task :create_series do
    videos = Video.all
    videos.each do |video|
      series = Series.first_or_create(
        name: video.name,
        alt_name: video.name
      )

      video.update(series: series)
    end
  end

  task :encode_all do
    encode_backend = EncodeBackend.new
    items = EncodeQueue.list()
    items.each do |item|
      encode_backend.queue << item
    end
    encode_backend.start
  end

  task :size do
    Video.all.each do |video|
      path = '/home/tett23/movie/frogbit/'+video.output_name
      if File.exists?(path)
        size = File.stat(path).size
        video.update(:filesize => size)
      end
    end
  end

  desc 'EPGのパースのてすと'
  task :parse_epg do
    Video.all.each do |video|
      name = video.name
      program = video.program.gsub(/\r\n?/, "\n").chomp.strip
      if program.blank?
        puts name+'のプログラム情報が空です'
        next
      end

      event_id = program.split("\n").last.gsub(/^.*EventID:(\d+?)\(.+$/, '\1').strip
      episode_number = nil
      episode_name = nil

      # 放送局によりかなり形式が異なる可能性あり。大体5行目に情報が入ってることが多い気がする
      episode_data = program.split("\n")[4]
      if episode_data.blank?
        puts name+'のプログラム情報はパース出来ません'
        next
      end

      circled_numbers = '①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳'
      circled_numbers_regex = /[①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳]$/

      episode_data_regex = /[#|第](\d+)[話]?.*「(.+?)」/
      only_episode_number_regex = /^.*#(\d+)$/
      only_episode_name_regex = /^.*#{name}「(.+)」$/

      if episode_data.match(episode_data_regex) # #12「hogehoge」みたいな形式
        matched = episode_data.match(episode_data_regex).to_a
        episode_number = matched[1]
        episode_name = matched[2]
      elsif episode_data.match(circled_numbers_regex) # サブタイ(2)みたいなの
        circled_number = episode_data.match(circled_numbers_regex).to_a.first
        episode_number = circled_numbers.index(circled_number)+1
        episode_name = episode_data.gsub(/^(.+)[①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳]$/, '\1')
      elsif episode_data =~ only_episode_name_regex
        episode_number = episode_data.gsub(only_episode_name_regex, '\1')
      elsif episode_data =~ only_episode_number_regex # サブタイなし、話数のみ
        episode_number = episode_data.gsub(only_episode_number_regex, '\1')
      else
        episode_name = episode_data
      end

      if name =~ only_episode_number_regex
        episode_number = name.gsub(only_episode_number_regex, '\1')
      elsif name =~ /^.+「(.+)」$/
        episode_name = name.gsub(/^.+「(.+)」$/, '\1')
        name = name.gsub(/^(.+)「.+」$/, '\1')
      end

      # 可能なら名前#(episode_count)「(episode_name)」_(event_id)の形式に変換する。
      # 変換できない場合はある情報だけでやる
      name = "#{name}#{episode_number ? '#'+episode_number.to_s : ''}#{episode_name ? "「#{episode_name}」" : ''}_#{event_id}"

      data = {
        name: name,
        episode_name: episode_name,
        episode_number: episode_number,
        event_id: event_id
      }
      p data
    end
  end
end
