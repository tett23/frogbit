require 'fileutils'
require 'kaminari/sinatra'

REC_REGEX = /^\d+\-(.+)(\.ts.+)?/

class Frogbit < Padrino::Application
  register SassInitializer
  register Padrino::Rendering
  register Padrino::Mailer
  register Padrino::Helpers
  register Kaminari::Helpers::SinatraHelpers

  enable :sessions

  before do
    add_breadcrumbs('frogbit', '/')
  end

  get :'/' do
    @videos = Video.list(:limit=>10)
    @encode_queue = EncodeQueue.list()

    render 'root/index'
  end

  error 404 do
    render 'errors/404'
  end

  error 505 do
    render 'errors/505'
  end
end
