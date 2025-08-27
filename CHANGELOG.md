## 0.6.4

- Add `EventTracer::BufferedLogger#flush` API to immediately flush buffered payloads
- Add top-level `EventTracer.flush_all` to flush all registered loggers that support flushing

## 0.6.3

- Fix another data race in `Buffer#flush`

## 0.6.2

- Refactor Appsignal, Datadog and Prometheus logger

## 0.6.1

- Fix data race in `Buffer`
