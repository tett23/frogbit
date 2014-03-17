# coding: utf-8

Frogbit.controllers :encode_logs, map: '/logs' do
  get :index do
    @logs = EncodeLog.list().page(params[:page] || 1)

    render 'logs/encode/index'
  end
end
