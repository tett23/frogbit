# coding: utf-8

require 'singleton'

class EncodeBackend
  include Singleton

  def initialize
    @encoding_item ||= nil
    @queue ||= EM::Queue.new
    @is_encoding ||= false
  end
  attr_accessor :queue

  def push(encode_item)
    @queue.push encode_item
  end

  def encoding_item
    @encoding_item
  end

  def start
    EM.defer do
      self.run
    end
  end

  def stop
    EM.stop
    @is_encoding = false
  end

  def encoding?
    !@queue.empty?
  end

  def run
    _encode = lambda do |encode_queue|
      @encoding_item = encode_queue
      @is_encoding = true

      EM.defer do
        encode(encode_queue)

        @encoding_item = nil
        @is_encoding = false
      end
    end
    encode = lambda do
      until @queue.empty?
        sleep 1

        unless @is_encoding
          @queue.pop do |encode_queue|
            _encode.call(encode_queue)

            encode.call()
          end
        end
      end
    end

    encode.call()
  end

  def encode(encode_queue)
    encode_log = EncodeLog.start(encode_queue)

    begin
      result = encode_queue.encode()
      p result

      encode_log.finish(result)
    rescue
      encode_log.finish({
        result: false,
        message: $!
      })
    ensure
      encode_queue.destroy
    end

    if result[:result]
      encode_queue.video.update(:is_encoded=>true, :encode_log=>result[:log], :saved_directory=>$config[:output_dir])
    end
  end
end
