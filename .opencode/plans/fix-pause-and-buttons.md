# Fix: pause/play button + move nav buttons to top-right

File: `lib/features/status/presentation/pages/view_status_page.dart`

## 1. Fix `toggleUIVisibility()` — strip timer logic

Old (lines 77-86):
```dart
void toggleUIVisibility() {
    setState(() {
      _isUIVisible = !_isUIVisible;
    });
    if (_isUIVisible && !_isPaused) {
      resumeStory();
    } else {
      pauseStory();
    }
}
```

New:
```dart
void toggleUIVisibility() {
    setState(() {
      _isUIVisible = !_isUIVisible;
    });
}
```

**Reason**: `toggleUIVisibility` should only toggle UI visibility, not
manage the timer. The long-press gesture handlers handle pausing/resuming
independently. The previous dual responsibility caused the pause-button
state to fight with the visibility toggle: when `_isPaused` was true,
`toggleUIVisibility` would call `pauseStory()` even when showing the UI
again, defeating the resume.

## 2. Fix long-press end handler

Old (lines 520-522):
```dart
onLongPressEnd: (_){
  toggleUIVisibility();
  resumeStory();
},
```

New:
```dart
onLongPressEnd: (_){
  toggleUIVisibility();
  if (_isUIVisible && !_isPaused) {
    resumeStory();
  }
},
```

**Reason**: Only resume on long-press-end when the UI is visible AND the
user hasn't explicitly paused via the pause button. This prevents the
long-press gesture from overriding the independent pause state.

## 3. Move navigation buttons from bottom-center to top-right

Old (lines 566-594):
```dart
if (!_isCurrentUserBatch)
  Positioned(
    left: 0,
    right: 0,
    bottom: 80,
    child: AnimatedOpacity(
      opacity: _isUIVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNavButton(
            icon: Icons.skip_previous,
            onTap: _currentBatchIndex > 0 ? _goToPreviousUser : null,
          ),
          const SizedBox(width: 24),
          _buildNavButton(
            icon: _isPaused ? Icons.play_arrow : Icons.pause,
            onTap: togglePause,
          ),
          const SizedBox(width: 24),
          _buildNavButton(
            icon: Icons.skip_next,
            onTap: _currentBatchIndex < widget.userStatusBatches.length - 1 ? _goToNextUser : null,
          ),
        ],
      ),
    ),
  ),
```

New:
```dart
if (!_isCurrentUserBatch)
  Positioned(
    top: 125,
    right: 12,
    child: AnimatedOpacity(
      opacity: _isUIVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNavButton(
            icon: Icons.skip_previous,
            onTap: _currentBatchIndex > 0 ? _goToPreviousUser : null,
          ),
          const SizedBox(height: 12),
          _buildNavButton(
            icon: _isPaused ? Icons.play_arrow : Icons.pause,
            onTap: togglePause,
          ),
          const SizedBox(height: 12),
          _buildNavButton(
            icon: Icons.skip_next,
            onTap: _currentBatchIndex < widget.userStatusBatches.length - 1 ? _goToNextUser : null,
          ),
        ],
      ),
    ),
  ),
```

**Reason**: User requested top-right corner. Changed layout from horizontal
`Row` to vertical `Column`, positioned at `top: 125, right: 12`.
