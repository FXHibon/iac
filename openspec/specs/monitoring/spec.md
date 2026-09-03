# Infrastructure Specification: Telemetry & Monitoring

## Purpose
Defines specifications for metrics collection, log aggregation, and dashboard visualization across VPS and RP5 environments.

## Requirements

### Requirement: Socket-Based Docker Metrics & Log Telemetry
Metrics and logs collection MUST remain immune to underlying containerd storage driver (`overlayfs`) metadata relocation.

#### Scenario: Docker Socket Scraping via Exporter & Grafana Alloy
- **GIVEN** containers running on Docker Engine with containerd snapshotter enabled
- **WHEN** telemetry services collect container stats and log streams
- **THEN** `docker-stats-exporter` MUST collect metrics directly via `/var/run/docker.sock` on internal port `9487`
- **AND** `Grafana Alloy` MUST tail container logs via Docker API socket components (`discovery.docker` and `loki.source.docker`) without mounting host log file paths.

### Requirement: Centralized Log Aggregation & Retention
Grafana Loki MUST ingest log streams from host and application containers.

#### Scenario: Loki Log Ingestion & 30-Day Retention
- **GIVEN** Loki listening internally on port `3100`
- **WHEN** logs are shipped by Alloy
- **THEN** Loki MUST index and store log entries with a enforced 30-day retention window
- **AND** make logs queryable within Grafana dashboards.
