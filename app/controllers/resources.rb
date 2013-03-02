# coding: utf-8

Frogbit.controllers :resources do
  get :video, :with=>:id, :provides=>[:mp4] do |id, format|
    @video = Video.detail(id)
    error 404 if @video.nil?

    path = ''
    case settings.environment
    when :development
      path = "#{PADRINO_ROOT}/out/#{@video.output_name}"
    when :production
    end

    send_file(path, :type=>'video/mp4')
  end
end
