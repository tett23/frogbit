# coding: utf-8

Frogbit.controllers :encode_logs, map: '/logs' do
  get :index do
    @logs = EncodeLog.list()
    if !params[:exist_ts].nil? && params[:exist_ts].to_boolean
      @logs = @logs.map do |encode_log|
        next nil if encode_log.video.nil?
        next nil unless encode_log.video.exists_ts?

        encode_log
      end.compact
    end


    render 'logs/encode/index'
  end
end
