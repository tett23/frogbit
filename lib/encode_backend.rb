# coding: utf-8

require 'singleton'

class EncodeBackend
  include Singleton

  def encode(encode_queue)
    encode_log = EncodeLog.start(encode_queue)

    begin
      result = encode_queue.encode()
      message = "#{result[:message]}\n#{result[:command]}"

      encode_log.finish(result)

      if result[:result]
        path = $config[:output_dir]+'/'+encode_queue.video.output_name
        size = nil
        if File.exists?(path)
          size = File.stat(path).size
        end

        encode_queue.video.update(:is_encoded=>true, :encode_log=>result[:log], :saved_directory=>$config[:output_dir], :filesize=>size)
      end
    rescue
      error = "#{$!.to_s}\n#{$!.backtrace.join("\n")}"
      message = error

      encode_log.finish({
        result: false,
        message: error
      })
    ensure
      encode_queue.destroy
    end

    message
  end
end
