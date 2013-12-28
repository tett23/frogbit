# coding: utf-8

Frogbit.controllers :search do
  get :index do
    @items = Video.search(params[:video]['query'])

    render 'search/index'
  end
end
