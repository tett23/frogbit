# coding: utf-8

Frogbit.controllers :disporsable, map: '/logs' do
  get :index do
    videos = Video.disporsable(params[:size])

    @logs = EncodeLog.list(video: videos).page(params[:page] || 1)
    @logs = Kaminari.paginate_array(@logs).page # ページネート可能な配列に変換

    render 'logs/encode/index'
  end

  delete :destroy, provides: :json do
    result = Video.disporsable(params[:size]).map do |video|
      video.destroy_ts
    end

    (result.size.zero? || (result.uniq.size == 1 && result.first == true)).to_json
  end
end
