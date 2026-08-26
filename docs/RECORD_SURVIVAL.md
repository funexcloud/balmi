# Balmi Record Survival

**Record First → Local Save → Recover → Sync**

Authoritative product spec lives in the uploaded Record Survival MD.
This document maps that spec to the current Flutter codebase.

## Architecture (as implemented)

```text
GPS / Motion
    ↓
Validation (GpsMotionFilter)
    ↓
SQLite points + session rows   ← local persistent store first
    ↓
RecordingPipeline / SessionEngine
    ↓
 ┌──────────────┐
 ↓              ↓
UI          sync_queue → SyncWorker → SyncClient
```

Never memory → server only. UI reads from local state that has already been
written (or is being written) to SQLite.

## Session ID

- UUID `sessionId` created in `SessionRepository.createSession`.
- Same id survives app restart, recovery, and sync retries.
- Server uniqueness is a Release-2 concern; client already keys by `sessionId`.

## What is implemented

| Area | Status | Notes |
|------|--------|--------|
| Local-first GPS points | Done | 1Hz `insertPoint` before UI-driven distance |
| Session + segments + laps | Done | Drift / SQLite |
| Sync queue + backoff | Done | Chunks of 60; `OfflineSyncClient` keeps queue |
| Process-kill recovery gate | Done | App start → unfinished session dialog |
| Recovery UI (이어가기 / 여기까지 저장) | Done | Distance, elapsed, last recorded time |
| Event + periodic checkpoint | Done | START/PAUSE/RESUME/LAP/ACTIVITY/GPS_LOST/RESTORED/BACKGROUND/STOP + 15s |
| Moving time restore | Done | From checkpoint on resume |
| Elapsed crash-gap absorb | Done | Pause clock rebuilt from checkpoint |
| Status language | Done | 기록 중 / 기기에 안전하게 저장 중 / 오프라인 기록 중 / 동기화 대기 / 기록 복구 완료 |
| GPS vs network axes | Partial | GPS live; network via injectable `RecordLink` (default unknown) |
| GPS gap protection | Partial | Checkpoint on lost/restored; filter still blocks bad jumps |
| Background recording | Done | Foreground service + wake lock (Android) |
| Idempotent sync ACK | TODO | Needs real server; client queues safely |
| Device reboot dedicated copy | TODO | Same recovery path works; reboot-specific copy not branched |
| GPS gap timeline UI | TODO | A●──gap──●B visualization |
| connectivity_plus probe | TODO | Wire real online/offline into `networkLink` |

## Key files

| Path | Role |
|------|------|
| `lib/data/recording/recording_pipeline.dart` | Local write, distance, checkpoint hooks |
| `lib/features/recording/recording_controller.dart` | Lifecycle, pause, recovery resume |
| `lib/domain/engines/session_checkpoint.dart` | Checkpoint model + policy |
| `lib/domain/engines/record_status.dart` | User-facing status language |
| `lib/domain/engines/recovery.dart` | Unfinished session detection |
| `lib/features/recovery/recovery_dialog.dart` | Recovery UI |
| `lib/data/repositories/session_repository.dart` | SQLite + `checkpoint:` AppKv |
| `lib/data/sync/sync_worker.dart` | Drain queue |
| `lib/app.dart` | Recovery gate before shell |

## Checkpoint payload

Stored under AppKv key `checkpoint:<sessionId>` as JSON:

- sessionId, elapsedMs, movingMs, pausedTotalMs
- distanceM, steps, activity, lapCount, paused
- lastLatitude / lastLongitude / lastGpsTimestampMs
- reason (`START` … `STOP` / `PERIODIC`), updatedAt

Cleared when the session closes (`closed` / `recovered`).

## Acceptance / P0 gate (manual)

See Record Survival §19–§20. Automated coverage today:

- Recovery detection (`test/recovery_test.dart`)
- Checkpoint policy + serialize (`test/session_checkpoint_test.dart`)
- Status language (`test/record_status_test.dart`)

Device QA still required for process kill, screen-off, OEM battery, and sync ACK.

## Product principle

> 걸음은 멈춰도, 기록은 멈추지 않도록.

**Record First. Local First. Recovery Ready.**
