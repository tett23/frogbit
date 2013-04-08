# coding: utf-8

Frogbit.controllers :series do
  get :index do
    @series = Series.list
    add_breadcrumbs('シリーズ一覧', url(:series, :index))

    render 'series/index'
  end

  get :show, with: :id do |id|
    @series = Series.get(id)
    error 404 if @series.nil?

    render 'series/show'
  end
end
