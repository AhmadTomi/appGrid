# AppGrid (app_grid)

**AppGrid** is a standalone, ultra-high-performance 2D virtualized DataGrid engine for Flutter, engineered to handle **100,000+ rows x 50+ columns at 60 FPS** and high-frequency streaming updates (50–100+ ticks/second) without frame drops or root rebuilds.

---

## Key Features

- **2D Viewport Virtualization:** Only visible rows (+1 buffer row) and visible columns are instantiated in the element tree (strict cell recycling).
- **Zero Root Rebuilds:** High-frequency cell/row streaming updates mutate isolated listeners, bypassing full-grid rebuilds.
- **Frame-Synced Batch Throttling:** Buffer high-velocity ticks (50–100+ events/sec) and flush them synchronized with `SchedulerBinding.scheduleFrameCallback`.
- **Developer Row & Batch Update Helpers:**
  - `controller.updateRow(originalIndex, data)`
  - `controller.updateRowAtDisplayIndex(displayIndex, data)`
  - `controller.updateRowById(id, data)` (via optional `rowIdGetter`)
  - `controller.patchRow(originalIndex, (current) => ...)`
  - `controller.updateRowWhere(predicate, updater)`
  - `controller.batchUpdateRows(map)`
- **Column Freezing (Left & Right Pinned Panes):** Freeze columns on the left or right edges while smoothly scrolling middle columns horizontally in lockstep vertically.
- **Adaptive Column Manipulation:** Drag-and-drop header reordering, right-edge resize handles, and double-click to auto-fit longest content.
- **Auto-Stretch Layout:**
  - Automatically stretches columns proportionally to fill 100% of the viewport width **only when $\sum \text{minWidth} < \text{ViewportWidth}$**.
  - If $\sum \text{minWidth} \ge \text{ViewportWidth}$, auto-stretch is inhibited, engaging smooth horizontal scrolling.
  - **Auto-stretch is automatically disabled when the user manually resizes any column**, preserving the user's manual widths.
  - Resetting column widths re-engages auto-stretch.
- **Dual-Index Selection:** Single-row selection returning `RowIndexInfo(originalIndex, displayIndex)`.
- **Full Keyboard Navigation:** `ArrowUp`, `ArrowDown`, `Home`, `End`, and `PageUp`/`PageDown` (jumps by count of visible viewport rows).
- **Selective State Persistence:** JSON import/export strictly covers `columnOrder`, `sortCriteria`, and `columnVisibility` (**column widths are strictly non-persisted**).
- **Export Utilities:** Built-in RFC 4180 CSV export and structured JSON export.

---

## Getting Started

### 1. Installation

Add `app_grid` to your `pubspec.yaml`:

```yaml
dependencies:
  app_grid:
    path: ../appGrid # or git/pub dependency
```

### 2. Quickstart Example

```dart
import 'package:flutter/material.dart';
import 'package:app_grid/app_grid.dart';

class User {
  final String id;
  final String name;
  final String role;

  const User({required this.id, required this.name, required this.role});
}

class UserGridPage extends StatefulWidget {
  const UserGridPage({super.key});

  @override
  State<UserGridPage> createState() => _UserGridPageState();
}

class _UserGridPageState extends State<UserGridPage> {
  late final AppGridController<User> _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppGridController<User>(
      rowIdGetter: (u) => u.id,
      initialData: [
        const User(id: '1', name: 'Alice', role: 'Engineer'),
        const User(id: '2', name: 'Bob', role: 'Designer'),
      ],
      columns: [
        GridColumn(
          id: 'id',
          label: 'ID',
          initialWidth: 80,
          pin: GridColumnPin.left, // Left pinned
          valueGetter: (u) => (u as User).id,
          cellBuilder: (context, user, info) => Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text((user as User).id),
          ),
        ),
        GridColumn(
          id: 'name',
          label: 'Name',
          initialWidth: 160,
          valueGetter: (u) => (u as User).name,
        ),
        GridColumn(
          id: 'role',
          label: 'Role',
          initialWidth: 140,
          valueGetter: (u) => (u as User).role,
        ),
      ],
      onRowSelected: (info) {
        print('Selected visual displayIndex: ${info.displayIndex}');
        print('Selected raw originalIndex: ${info.originalIndex}');
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AppGrid Quickstart')),
      body: AppGrid<User>(
        controller: _controller,
        rowHeight: 48.0,
        headerHeight: 48.0,
      ),
    );
  }
}
```

---

## Row & Batch Mutation Helper APIs

No need to manually loop through lists or rebuild the entire grid. `AppGridController<T>` provides high-level helpers:

```dart
// 1. Direct 1-row update by dataset index
_controller.updateRow(0, updatedUser);

// 2. Direct 1-row update by active visual index (post-sort)
_controller.updateRowAtDisplayIndex(0, updatedUser);

// 3. Update by ID (when rowIdGetter is configured)
_controller.updateRowById('usr_42', updatedUser);

// 4. Functional patch of existing state
_controller.patchRow(index, (currentUser) {
  return currentUser.copyWith(role: 'Senior Lead');
});

// 5. Update rows matching a predicate
_controller.updateRowWhere(
  (user) => user.isExpired,
  (user) => user.copyWith(status: 'Inactive'),
);

// 6. High-volume batch updates (coalesced to next 60 FPS frame)
_controller.batchUpdateRows({
  0: updatedUserA,
  5: updatedUserB,
});
```

---

## Interactive Feature Showcase & Documentation App

A full showcase application is included in `example/lib/main.dart` with a side-by-side split layout:
- **Left Pane:** Interactive live demo for every feature.
- **Right Pane:** Complete, formatted code snippet with a 1-click **"Copy Code"** button.

To run the showcase:
```bash
cd example
flutter run
```

---

## Architectural Verification & Acceptance Criteria (SDD)

| Spec ID | Requirement & Invariant | Status |
|---|---|---|
| **AC-01** | 100,000 rows x 50 columns 2D virtualization | Verified (Passed) |
| **AC-02** | 60 updates/sec cell mutations with 0 root rebuilds | Verified (Passed) |
| **AC-03** | DualIndexMap post-sort preserves raw originalIndex | Verified (Passed) |
| **AC-04** | PageDown shifts selection by visible row count | Verified (Passed) |
| **AC-05** | State persistence JSON strictly contains no column widths | Verified (Passed) |
| **AC-06** | Auto-stretch distributes excess space with zero blank canvas | Verified (Passed) |

Run the verification test suite:
```bash
flutter test
flutter analyze
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

