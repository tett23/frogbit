Frogbit.helpers do
  def video_class(video)
    add_classes = []

    add_classes << (video.is_encoded ? 'encoded' : 'unencoded')
    add_classes << (video.is_watched ? 'watched' : 'unwatched')

    add_classes.join(' ')
  end

  def video_path(video)
    path = url(:resources, :video, :id=>@video.id)
    path = path+'.mp4'

    path
  end
end
