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

  def free_space
    stat = Sys::Filesystem.stat($config[:input_dir])
    free = (stat.blocks_available * stat.block_size).to_f / 1024 / 1024 / 1024

    free.to_s.scan(/^(\d+\.\d{0,3})/)[0][0].to_f.to_s + 'GB'
  end
end
