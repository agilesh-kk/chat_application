# Chat Page: Adapt to Map<String, Message> + List<String> ids

State changed from `List<Message> messages` to `Map<String, Message> messages` + `List<String> ids` (ordered keys).

## Changes in `chat_page.dart`

### Line 174-175 — scroll position label
```dart
// Before:
if (state is ChatLoaded && topIndex < state.messages.length) {
  final message = state.messages[topIndex];

// After:
if (state is ChatLoaded && topIndex < state.ids.length) {
  final message = state.messages[state.ids[topIndex]];
```

### Line 211 — reply tap index lookup
```dart
// Before:
final index = state.messages.indexWhere((m) => m.id == replyToId);

// After:
final index = state.ids.indexWhere((id) => id == replyToId);
```

### Line 593-595 — timeline message check
```dart
// Before:
if (messageId != null && cl.messages.any((m) => m.id == messageId)) {

// After:
if (messageId != null && cl.messages.containsKey(messageId)) {
```

### Lines 658-668 — messages variable + auto-scroll
```dart
// Before:
final messages = state.messages;
if(messages.isNotEmpty){
  if(lastMessageId==null){
    lastMessageId = messages[0].id;
  } else if(lastMessageId != messages[0].id && _scrollController.isAttached){
    _scrollController.scrollTo(index: 0, ...);
    lastMessageId = messages[0].id;
  }
}

// After:
final messages = state.messages;
final ids = state.ids;
if(ids.isNotEmpty){
  if(lastMessageId==null){
    lastMessageId = ids[0];
  } else if(lastMessageId != ids[0] && _scrollController.isAttached){
    _scrollController.scrollTo(index: 0, ...);
    lastMessageId = ids[0];
  }
}
```

### Line 676 — highlight message index lookup
```dart
// Before:
final highlightIndex = messages.indexWhere((m) => m.id == widget.highlightMessageId);

// After:
final highlightIndex = ids.indexWhere((id) => id == widget.highlightMessageId);
```

### Line 702 — itemCount
```dart
// Before:
itemCount: messages.length,

// After:
itemCount: ids.length,
```

### Line 707 — message lookup in builder
```dart
// Before:
final message = messages[index];

// After:
final message = messages[ids[index]];
```

### Line 724 — date header check
```dart
// Before:
if (_shouldShowDateHeader(messages, index))

// After:
if (_shouldShowDateHeader(messages, ids, index))
```

### Line 779 — sticky date header
```dart
// Before:
_buildStickyDateHeader(state.dateLabel!, messages)

// After:
_buildStickyDateHeader(state.dateLabel!, messages, ids)
```

### Lines 827-856 — _buildStickyDateHeader signature + body
```dart
// Before:
Widget _buildStickyDateHeader(String label, List<Message> messages) {
  ...
  print(messages[0].createdAt);
  DateTime? picked = await showDatePicker(
    context: context,
    firstDate: messages[messages.length-1].createdAt,
    lastDate: DateTime.now(),
  );
  if(picked != null){
    final index = messages.lastIndexWhere(
      (element) => element.createdAt.eqvYearMonthDay(picked),
    );

// After:
Widget _buildStickyDateHeader(String label, Map<String, Message> messages, List<String> ids) {
  ...
  print(messages[ids[0]]!.createdAt);
  DateTime? picked = await showDatePicker(
    context: context,
    firstDate: messages[ids[ids.length-1]]!.createdAt,
    lastDate: DateTime.now(),
  );
  if(picked != null){
    final index = ids.lastIndexWhere(
      (id) => messages[id]!.createdAt.eqvYearMonthDay(picked),
    );
```

### Lines 858-863 — _shouldShowDateHeader signature + body
```dart
// Before:
bool _shouldShowDateHeader(List<Message> messages, int index) {
  if (index == messages.length - 1) return true;
  final currentDate = DateTime(messages[index].createdAt.year, ...);
  final nextDate = DateTime(messages[index + 1].createdAt.year, ...);

// After:
bool _shouldShowDateHeader(Map<String, Message> messages, List<String> ids, int index) {
  if (index == ids.length - 1) return true;
  final currentDate = DateTime(messages[ids[index]]!.createdAt.year, ...);
  final nextDate = DateTime(messages[ids[index + 1]]!.createdAt.year, ...);
```

## Total: 12 edit sites
