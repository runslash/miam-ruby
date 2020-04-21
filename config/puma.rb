tag 'miam-http-server'
directory ENV.fetch('MIAM_DIRECTORY', File.realpath(File.dirname(__FILE__) + '/../'))
threads ENV.fetch('MIAM_WORKER_THREADS', 4).to_i, ENV.fetch('MIAM_WORKER_THREADS', 4).to_i
if ENV.key?('MIAM_BIND_URL')
  bind ENV['MIAM_BIND_URL']
else
  port ENV.fetch('MIAM_PORT', 8808)
end
environment ENV.fetch('MIAM_ENV', 'development')
stdout_redirect ENV['MIAM_LOG_FILE'], ENV['MIAM_LOG_FILE'] if ENV.key?('PUMA_LOG_FILE')
workers ENV.fetch('MIAM_WORKERS', 2).to_i
queue_requests ENV.fetch('MIAM_QUEUE_REQUESTS', '0') == '1'
prune_bundler
drain_on_shutdown true
