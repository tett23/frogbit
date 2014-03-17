# coding: utf-8

Frogbit.controllers :resources do
  get :video, :with=>:id, :provides=>[:mp4] do |id, format|
    @video = Video.detail(id)
    error 404 if @video.nil?

    path = ''
    case settings.environment
    when :development
      path = "#{$config[:output_dir]}/#{@video.output_name}"
    when :production
    end

    status 206

    send_file(
      path,
      type: 'video/mp4',
      buffer_size: 1024
    )
  end
end
