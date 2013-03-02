# coding: utf-8

Frogbit.controllers :videos do
  get :index do
    @videos = Video.list()
    add_breadcrumbs('動画一覧', url(:videos, :index))

    render 'videos/index'
  end

  get :show, :with=>:id do |id|
    @video = Video.detail(id)
    error 404 if @video.nil?

    add_breadcrumbs('動画一覧', url(:videos, :index))
    add_breadcrumbs(@video.output_name, url(:videos, :show, :id=>id))

    render 'videos/show', :layout=>'application'
  end
end
