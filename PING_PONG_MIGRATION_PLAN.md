# Architecture Plan: The Unified Ping-Pong Engine (Phased Rollout)

To achieve mathematically perfect, zero-latency segment transitions without compromising the stability of the Host App (`karaoke_app`), we will adopt a strict, isolated phased rollout.

## The Core Concept: Dual-Deck Ping-Pong
Calling `seekTo()` on compressed media forces a hardware decoder flush, causing an unavoidable ~150ms stutter. To eliminate this, we will elevate the `_playerA` / `_playerB` logic currently hidden inside the `MedleyUnifiedController` and make it the standard for the base `VoxPlayerController`. The UI will use a Flutter `Stack` to seamlessly swap between two active video surfaces.

---

## The Phased Implementation Strategy

### Phase 1: Core Engine Refactoring (Isolated) [COMPLETED]
We will refactor `VoxPlayerController` and the `VoxPlayer` widget inside the `vox_player_core` package to support the dual-deck architecture natively for both Audio and Video. 
* **Impact:** This happens entirely inside the `vox_player_core` package.

### Phase 2: Shared Transition Editor UI [COMPLETED]
We will extract the graphical Transition Editor out of the Sequence Dialog into a standalone `TransitionEditorWidget`. We will wire its "Preview" button to use the new Ping-Pong Engine (loading Segment 1 into Deck A, and Segment 2 into Deck B).
* **Impact:** The Sequence Editor Dialog gets zero-latency previews, allowing you to accurately align beats visually.

### Phase 3: Medley Builder Integration [COMPLETED]
We will embed the new `TransitionEditorWidget` into the Medley Builder, granting it the exact same graphical slider and zero-latency preview capabilities.
* **Crucially**, because we elevated the Ping-Pong engine directly into `VoxPlayer` and `VoxPlayerController` (which now uses a `Stack` of two hardware-accelerated `Video` widgets), the Medley Builder will natively support building and previewing **Seamless Local Video Medleys**, not just audio!
* **Impact:** `practice_app` and Medley Creation become extremely powerful and visually accurate.

### Phase 4: Wait & Verify (The Sandbox) [CURRENT STATE]
At this stage, we **stop**. 
Because the Host App (`karaoke_app`) uses its own custom `PlayerScreen.dart` for Public Display and Host View, it will remain **100% untouched and functional**. It will still have the 150ms sequence stutter, but its YouTube, Smule, and queue sync logic will remain rock-solid.
* You can extensively test the new zero-latency engine inside the `practice_app` and Sequence Editor Dialog safely.

### Phase 5: Host App Migration (Future / Slow Incorporation) [PENDING]
Once the Ping-Pong engine is proven perfectly stable in the core, we will begin slowly porting `karaoke_app`'s custom features (like the Smule proxy stream) into `VoxPlayer`. Only when feature parity is reached will we swap out the old `PlayerScreen` for the new `VoxPlayer`.
