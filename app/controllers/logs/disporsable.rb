# coding: utf-8

Frogbit.controllers :disporsable, map: '/logs' do
  get :index do
    videos = Video.disporsable(params[:size])

    video_ids = videos.map do |v|
      v.id
    end
    @logs = EncodeLog.list(video_id: video_ids).page(params[:page] || 1)
    @logs = Kaminari.paginate_array(@logs).page # ページネート可能な配列に変換

    render 'logs/encode/index'
  end

  delete :destroy, provides: :json do
    result = Video.disporsable(params[:size]).map do |video|
      begin
        video.destroy_ts
      rescue
        p $!
      end
    end

    (result.size.zero? || (result.uniq.size == 1 && result.first == true)).to_json
  end
end
