tag 'miam-http-server'
directory ENV['PUMA_DIRECTORY'] if ENV.key?('PUMA_DIRECTORY')
threads ENV.fetch('PUMA_MIN_THREADS', 4).to_i, ENV.fetch('PUMA_MAX_THREADS', 4).to_i
port ENV.fetch('PUMA_PORT') { 8808 }
environment ENV.fetch('RAILS_ENV') { 'development' }
stdout_redirect ENV['PUMA_LOG_FILE'], ENV['PUMA_LOG_FILE'] if ENV.key?('PUMA_LOG_FILE')
# pidfile ENV.fetch('PUMA_PID_FILE', 'tmp/puma.pid')
workers ENV.fetch('PUMA_WORKERS', 4).to_i
queue_requests false
prune_bundler
drain_on_shutdown true
