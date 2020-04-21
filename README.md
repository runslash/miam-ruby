# Miam

## Installation
```sh
gem install miam
```

## Run

### Simple
```sh
miamctl start
```

### Advanced Options
- `-w`, `--workers` - Number of server workers (Puma Workers count)
- `-t`, `--threads` - Number of threads per worker (Puma Threads count)
- `--queue-requests` - Enable Puma `queue_requests` setting
- `-p`, `--port` - Server port, default: 8808
- `-b`, `--bind` - Bind address, example: tcp://0.0.0.0:8808 (overwrite `--port` option)
- `--redis-url` - Redis URL to use as cache store instead of LRU, example: redis://localhost:6789
- `-d`, `--daemon` - Daemonize process
- `--keep-file-descriptors` - Pass `--keep-file-descriptors` to `bundle exec puma` used with SystemD service/socket
```
miamctl start --redis-url=redis://localhost:6789 --workers 2 --threads 4 --bind tcp://0.0.0.0:8808
```

## Test

```sh
siege -c4 -t60S -r 100 \
    --content-type "application/json" \
    'http://localhost:8808/a POST {"operation_name":"iam:DescribeUser","auth_token":"MIAM-AK-V1 credentials=AKRLDNFSQMWK5JN4FHGC3Q; date=1587420316; signature=41f25a0c0be60980a863bcd08d054d45d76db9d381513aa540a4ae5265a4a50e","auth_headers":{"x":"x"},"auth_body_signature":"bf21a9e8fbc5a3846fb05b4fa0859e0917b2202f"}'
```
