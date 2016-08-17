workers Integer(ENV['PUMA_WORKERS'] || 1)
min_threads_count = Integer(ENV['PUMA_MIN_THREADS'] || 12)
max_threads_count = Integer(ENV['PUMA_MAX_THREADS'] || 12)
threads min_threads_count, max_threads_count

preload_app!

rackup DefaultRackup
port ENV['PORT'] || 3000
environment ENV['RACK_ENV'] || 'development'
