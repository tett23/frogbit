# coding: utf-8

Frogbit.controllers :logs do
  get :index do
    @logs = EncodeLog.list()

    render 'logs/index'
  end
end
