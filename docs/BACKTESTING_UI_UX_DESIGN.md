# Backtesting UI/UX Design & Enhancement Specification

**Document Version:** 1.0  
**Date:** February 2026  
**Prepared For:** Development Team & Stakeholders  
**Status:** Awaiting Approval

---

## Executive Summary

This document outlines comprehensive UI/UX enhancements for the backtesting system, focusing on improved log visualization, debug capabilities, live progress tracking, input sheet integration, template functionality, and time management features. The design prioritizes clarity, real-time feedback, and user control while maintaining professional aesthetics suitable for quantitative analysis workflows.

---

## Table of Contents

1. [Log Categorization & Visualization](#1-log-categorization--visualization)
2. [Debug Logs Integration](#2-debug-logs-integration)
3. [Live Log Streaming](#3-live-log-streaming)
4. [Input Sheet Integration](#4-input-sheet-integration)
5. [Template Functionality](#5-template-functionality)
6. [Progress Tracking & Time Management](#6-progress-tracking--time-management)
7. [UI Component Specifications](#7-ui-component-specifications)
8. [Interaction Patterns](#8-interaction-patterns)
9. [Accessibility & Performance](#9-accessibility--performance)
10. [Implementation Phases](#10-implementation-phases)

---

## 1. Log Categorization & Visualization

### 1.1 Log Categories

The system shall categorize all backtesting logs into three distinct levels:

| Category | Purpose | Visual Treatment |
|----------|---------|------------------|
| **Informational** | Standard execution flow, status updates, successful operations | Blue/Neutral color scheme, info icon (ℹ️) |
| **Warning** | Non-critical issues, performance degradation, recoverable errors | Amber/Yellow color scheme, warning icon (⚠️) |
| **Error** | Critical failures, data inconsistencies, execution blocks | Red color scheme, error icon (❌) |

### 1.2 Visual Design Specification

#### Color Palette
```css
/* Informational Logs */
--log-info-bg: #E3F2FD;        /* Light blue background */
--log-info-border: #2196F3;    /* Blue border */
--log-info-text: #1565C0;      /* Dark blue text */
--log-info-icon: #2196F3;      /* Blue icon */

/* Warning Logs */
--log-warning-bg: #FFF8E1;     /* Light amber background */
--log-warning-border: #FFC107; /* Amber border */
--log-warning-text: #F57C00;   /* Dark amber text */
--log-warning-icon: #FF9800;   /* Orange icon */

/* Error Logs */
--log-error-bg: #FFEBEE;       /* Light red background */
--log-error-border: #F44336;   /* Red border */
--log-error-text: #C62828;     /* Dark red text */
--log-error-icon: #D32F2F;     /* Red icon */
```

#### Typography
- **Font Family:** Monospace font (e.g., 'Courier New', 'Consolas', 'Monaco') for log content
- **Font Size:** 13px base, 12px for timestamps
- **Line Height:** 1.5 for readability
- **Font Weight:** Regular for content, Medium for category labels

### 1.3 Log Entry Component Structure

Each log entry shall display:

```
┌─────────────────────────────────────────────────────────────┐
│ [ICON] [TIMESTAMP] [CATEGORY] │ [FILTER ICON] [COPY ICON] │
├─────────────────────────────────────────────────────────────┤
│ Log message content here...                                  │
│ Multi-line content supported with proper indentation        │
└─────────────────────────────────────────────────────────────┘
```

**Component Breakdown:**
- **Icon:** Category-specific icon (info/warning/error) - 16x16px
- **Timestamp:** Format `HH:MM:SS.mmm` (24-hour format with milliseconds)
- **Category Badge:** Colored pill badge with category name
- **Message:** Full log content with syntax highlighting for code/values
- **Actions:** Filter by category, copy log entry, expand/collapse details

### 1.4 Filtering & Search

**Filter Controls:**
- Toggle buttons for each category (Info/Warning/Error)
- "Show All" / "Clear Filters" button
- Active filter count badge
- Search bar with real-time filtering by message content

**Visual State:**
- Active filter: Filled background with category color
- Inactive filter: Outlined border, grayed out
- Filtered count indicator: "Showing X of Y logs"

---

## 2. Debug Logs Integration

### 2.1 Debug Mode Toggle

**Location:** Backtest configuration panel / Run settings

**Component Design:**
```
┌─────────────────────────────────────────┐
│ ☐ Enable Debug Logs                    │
│   Show detailed execution information   │
│   (May impact performance)              │
└─────────────────────────────────────────┘
```

**Behavior:**
- Checkbox toggle with descriptive label
- Tooltip on hover: "Enables verbose logging including variable states, execution paths, and intermediate calculations"
- Warning indicator when enabled: "Debug mode may slow down execution"
- State persists across sessions (user preference)

### 2.2 Debug Log Characteristics

When debug mode is enabled, logs shall include:

1. **Variable State Dumps**
   - Variable names and current values
   - Data type indicators
   - Memory addresses (optional, developer mode)

2. **Execution Path Tracking**
   - Function entry/exit points
   - Conditional branch decisions
   - Loop iterations (with iteration count)

3. **Performance Metrics**
   - Function execution time
   - Memory allocation/deallocation
   - Database query execution times

4. **Intermediate Calculations**
   - Step-by-step computation breakdowns
   - Formula evaluations
   - Data transformation stages

### 2.3 Debug Log Visual Treatment

**Distinct Styling:**
- **Background:** Subtle gray background (`#F5F5F5`)
- **Border:** Dashed border (`#CCCCCC`) to differentiate from standard logs
- **Prefix:** `[DEBUG]` badge in gray
- **Collapsible Sections:** Nested debug information in expandable sections

**Example Structure:**
```
┌─────────────────────────────────────────────────────────────┐
│ [DEBUG] Variable State Dump                                │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ portfolio_value: 125000.50                              │ │
│ │ current_position: LONG                                  │ │
│ │ entry_price: 45.23                                     │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Live Log Streaming

### 3.1 Real-Time Display Requirements

**Core Functionality:**
- Logs appear immediately as they are generated during backtest execution
- No manual refresh required
- Smooth scrolling with auto-scroll to latest log option
- Performance optimized for high-frequency log generation (100+ logs/second)

### 3.2 UI Components

#### 3.2.1 Log Container

**Layout:**
- Fixed-height scrollable container (default: 60vh, user-adjustable)
- Virtual scrolling for performance (render only visible logs + buffer)
- Smooth scroll animation (ease-in-out, 300ms)

**Auto-Scroll Toggle:**
```
┌─────────────────────────────────────────┐
│ [↓] Auto-scroll to latest               │
│     (Enabled/Disabled toggle)           │
└─────────────────────────────────────────┘
```

**Behavior:**
- When enabled: Automatically scrolls to bottom on new log entry
- When disabled: User can manually scroll to review historical logs
- Visual indicator when new logs arrive while auto-scroll is disabled (badge: "X new logs")

#### 3.2.2 Live Indicator

**Visual Element:**
- Pulsing dot indicator (green) when backtest is running
- Status text: "Live" or "Paused" or "Completed"
- Connection status indicator (if applicable for remote execution)

**Design:**
```
┌─────────────────────────────────────────┐
│ ● Live  │  Logs: 1,234  │  [Clear]     │
└─────────────────────────────────────────┘
```

### 3.3 Performance Optimization

**Technical Requirements:**
- **Debouncing:** Batch log updates (max 60 FPS for UI updates)
- **Throttling:** Limit log rendering to prevent UI freeze
- **Virtualization:** Use virtual scrolling (e.g., `react-window`, `react-virtualized`)
- **Lazy Loading:** Load older logs on scroll-up (pagination)
- **Memory Management:** Limit in-memory log count (e.g., keep last 10,000 entries)

**User Controls:**
- Pause log streaming (pause button)
- Clear logs (with confirmation dialog)
- Export logs to file (CSV/JSON/TXT)

---

## 4. Input Sheet Integration

### 4.1 Research Summary

**Current State Analysis:**
- Input sheets are typically Excel/CSV files containing:
  - Strategy parameters
  - Asset lists
  - Date ranges
  - Risk parameters
  - Custom configurations

**Integration Approaches:**

#### Approach A: File Upload (Recommended)
- **Pros:** Simple, familiar, supports complex data structures
- **Cons:** Requires file management, validation overhead
- **Best For:** One-time or infrequent configuration changes

#### Approach B: In-UI Form Builder
- **Pros:** No file handling, immediate validation, guided input
- **Cons:** Limited flexibility for complex configurations
- **Best For:** Standard backtest configurations

#### Approach C: Hybrid (File Upload + UI Override)
- **Pros:** Flexibility of files + convenience of UI
- **Cons:** More complex implementation
- **Best For:** Power users and varied use cases

### 4.2 Recommended Solution: Hybrid Approach

### 4.3 UI Design Specification

#### 4.3.1 Input Sheet Upload Panel

**Location:** Backtest configuration section

**Component Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│ Input Configuration                                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [📁 Upload Input Sheet]  or  [📝 Use Template]            │
│                                                             │
│  Selected File: strategy_params_2026.xlsx                  │
│  [Preview] [Remove] [Download Template]                    │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │ Sheet Preview (if Excel):                             │ │
│  │                                                       │ │
│  │   Parameter    │ Value    │ Type    │ Validation    │ │
│  │   ────────────┼──────────┼─────────┼───────────────│ │
│  │   start_date   │ 2024-01  │ date    │ ✓ Valid       │ │
│  │   end_date     │ 2024-12  │ date    │ ✓ Valid       │ │
│  │   capital      │ 100000   │ number  │ ✓ Valid       │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  [✓] Validate before run                                   │
│  [✓] Override with UI form (if conflicts)                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### 4.3.2 File Upload Flow

1. **Upload Trigger:**
   - Drag-and-drop zone (highlighted on drag-over)
   - Click to browse file dialog
   - Supported formats: `.xlsx`, `.xls`, `.csv`, `.json`

2. **Validation:**
   - **Immediate:** File format check, file size limit (max 10MB)
   - **Post-Upload:** Schema validation, data type checks, required field verification
   - **Visual Feedback:** 
     - ✓ Green checkmark for valid fields
     - ⚠️ Yellow warning for optional/format issues
     - ❌ Red error for invalid/critical issues

3. **Preview & Edit:**
   - Table view of uploaded data
   - Inline editing for corrections
   - Add/remove rows capability
   - Export modified sheet

#### 4.3.3 Template System Integration

**Template Library:**
- Pre-configured templates for common strategies
- Custom user-created templates
- Template categories (e.g., "Momentum", "Mean Reversion", "Pairs Trading")

**Template Selection UI:**
```
┌─────────────────────────────────────────────────────────────┐
│ Select Template                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [Search templates...]                                      │
│                                                             │
│  ┌──────────────────┐  ┌──────────────────┐                │
│  │ 📄 Momentum     │  │ 📄 Mean Revert   │                │
│  │ Basic           │  │ Basic            │                │
│  │ [Use] [Preview] │  │ [Use] [Preview]  │                │
│  └──────────────────┘  └──────────────────┘                │
│                                                             │
│  [Create New Template]                                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 4.4 Data Mapping & Validation

**Schema Definition:**
- JSON schema file defining expected structure
- Field mappings: UI field name ↔ Sheet column name
- Data type definitions (string, number, date, boolean, array)
- Validation rules (min/max, regex patterns, required fields)

**Error Handling:**
- Clear error messages with row/column references
- Suggestions for fixing common errors
- "Fix All" button for auto-correctable issues (with user confirmation)

---

## 5. Template Functionality

### 5.1 Current Issues Analysis

**Common Template Problems:**
1. Templates not saving user modifications
2. Template variables not resolving correctly
3. Template inheritance/overrides not working
4. Template validation failing silently

### 5.2 Template Fix Specification

#### 5.2.1 Template Save Functionality

**Save Flow:**
```
┌─────────────────────────────────────────────────────────────┐
│ Save as Template                                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Template Name: [________________________]                  │
│  Description:   [________________________]                  │
│                 [________________________]                  │
│                                                             │
│  Category: [Dropdown: Strategy Type ▼]                      │
│                                                             │
│  Include in template:                                       │
│    [✓] Strategy parameters                                  │
│    [✓] Asset list                                          │
│    [✓] Date range                                          │
│    [ ] Current results (exclude)                           │
│                                                             │
│  [Cancel]  [Save Template]                                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Validation:**
- Template name required, unique within user's templates
- Description optional but recommended
- At least one configuration element must be included
- Success confirmation: "Template 'X' saved successfully"

#### 5.2.2 Template Variable Resolution

**Variable System:**
- Supported variables: `${DATE}`, `${TIME}`, `${USER}`, `${RANDOM_ID}`
- Custom variables: User-defined variables in template
- Resolution preview: Show resolved values before running

**UI Component:**
```
┌─────────────────────────────────────────────────────────────┐
│ Template Variables                                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Variable        │ Value              │ Status              │
│  ───────────────┼────────────────────┼─────────────────────│ │
│  ${DATE}         │ 2026-02-22        │ ✓ Resolved          │ │
│  ${START_DATE}   │ [Not set]         │ ⚠️ Required         │ │
│  ${CAPITAL}      │ 100000            │ ✓ Resolved          │ │
│                                                             │
│  [Set Missing Variables]                                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### 5.2.3 Template Override System

**Override Rules:**
1. User modifications override template defaults
2. Explicit "Reset to Template" button to restore defaults
3. Visual indicator for modified fields (blue highlight)
4. Diff view: Show template value vs. current value

**UI Indicator:**
- Modified field: Blue border, "Modified" badge
- Template value: Grayed out, strikethrough
- Current value: Bold, highlighted

#### 5.2.4 Template Validation

**Validation Checks:**
- Required fields present
- Data types match expected types
- Value ranges within acceptable limits
- Dependencies satisfied (e.g., end_date > start_date)

**Error Display:**
- Inline validation errors below each field
- Summary panel: "X errors found, Y warnings"
- "Fix All" suggestions where applicable

---

## 6. Progress Tracking & Time Management

### 6.1 Progress Metrics

**Tracked Metrics:**
1. **Elapsed Time:** Total time since backtest started
2. **Progress Percentage:** Completion percentage (if calculable)
3. **Estimated Time of Arrival (ETA):** Predicted completion time
4. **Background Time:** Time elapsed while user performs other tasks
5. **Active Processing Time:** Time spent actively processing (excludes pauses)

### 6.2 UI Component Design

#### 6.2.1 Progress Panel

**Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│ Backtest Progress                                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ████████████████░░░░░░░░  65% Complete                    │
│                                                             │
│  Elapsed Time:        02:34:15                             │
│  Estimated Remaining: 01:22:45                             │
│  ETA:                  16:45:30                            │
│                                                             │
│  Background Time:      00:45:20                             │
│  Active Processing:    01:48:55                            │
│                                                             │
│  [⏸️ Pause]  [⏹️ Stop]  [📊 View Details]                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### 6.2.2 Time Display Format

**Format Specification:**
- **Elapsed/Remaining:** `HH:MM:SS` (hours:minutes:seconds)
- **ETA:** `HH:MM:SS` or `MMM DD, YYYY HH:MM` (if >24 hours)
- **Background Time:** `HH:MM:SS` with tooltip: "Time elapsed while you were on other tabs/windows"
- **Active Processing:** `HH:MM:SS` with tooltip: "Time spent actively processing (excludes pauses)"

**Visual Hierarchy:**
- Primary metrics: Large, bold font (18px)
- Secondary metrics: Medium font (14px)
- Labels: Small, gray font (12px)

#### 6.2.3 Progress Bar Design

**Visual Treatment:**
- **Fill Color:** Gradient from primary color to lighter shade
- **Background:** Light gray (`#E0E0E0`)
- **Animation:** Smooth progress updates (ease-out, 500ms)
- **Indeterminate State:** Animated shimmer when progress cannot be calculated

**States:**
- **Running:** Animated progress bar
- **Paused:** Grayed out, "PAUSED" label
- **Completed:** Full bar, green checkmark
- **Error:** Red bar, error icon

#### 6.2.4 Background Time Tracking

**Implementation Logic:**
- Track when user switches tabs/windows (Page Visibility API)
- Track when user minimizes application window
- Track when user interacts with other applications (if detectable)
- Resume tracking when user returns to backtest view

**Visual Indicator:**
- Background time badge: "⏱️ Background: 00:45:20"
- Tooltip: "Time elapsed while you were away from this tab"
- Optional: Notification when returning: "Backtest continued for X minutes in background"

### 6.3 ETA Calculation

**Algorithm:**
1. **If Progress Available:**
   ```
   ETA = (Elapsed Time / Progress Percentage) - Elapsed Time
   ```

2. **If Progress Unavailable:**
   - Use historical average completion time for similar backtests
   - Display: "ETA: ~X minutes (based on similar runs)"

3. **Dynamic Updates:**
   - Recalculate ETA every 10 seconds
   - Smooth ETA transitions (avoid jarring changes)
   - Confidence indicator: "High confidence" / "Estimated"

**UI Display:**
- ETA value with confidence badge
- Trend indicator: ⬆️ Increasing / ⬇️ Decreasing / ➡️ Stable

---

## 7. UI Component Specifications

### 7.1 Log Viewer Component

**Props/Configuration:**
```typescript
interface LogViewerProps {
  logs: LogEntry[];
  autoScroll: boolean;
  showDebug: boolean;
  filters: LogCategory[];
  onFilterChange: (filters: LogCategory[]) => void;
  onClear: () => void;
  onExport: (format: 'csv' | 'json' | 'txt') => void;
}
```

**Performance Targets:**
- Render 1000 logs in <100ms
- Handle 100 logs/second without UI freeze
- Memory usage <50MB for 10,000 log entries

### 7.2 Progress Tracker Component

**Props/Configuration:**
```typescript
interface ProgressTrackerProps {
  elapsedTime: number;        // seconds
  progress: number;           // 0-100
  eta: number;                // seconds until completion
  backgroundTime: number;      // seconds
  activeTime: number;         // seconds
  status: 'running' | 'paused' | 'completed' | 'error';
  onPause: () => void;
  onStop: () => void;
}
```

**Update Frequency:**
- Time displays: Every 1 second
- Progress bar: Every 100ms (smooth animation)
- ETA recalculation: Every 10 seconds

### 7.3 Input Sheet Upload Component

**Props/Configuration:**
```typescript
interface InputSheetUploadProps {
  acceptedFormats: string[];   // ['.xlsx', '.csv', '.json']
  maxFileSize: number;         // bytes
  schema: ValidationSchema;
  onUpload: (file: File) => Promise<ValidationResult>;
  onPreview: (data: any) => void;
  onRemove: () => void;
}
```

**Validation Response:**
```typescript
interface ValidationResult {
  valid: boolean;
  errors: ValidationError[];
  warnings: ValidationWarning[];
  data: ParsedData;
}
```

---

## 8. Interaction Patterns

### 8.1 Log Interaction

**User Actions:**
1. **Filter by Category:** Click category toggle → Instant filter
2. **Search Logs:** Type in search bar → Real-time filtering
3. **Copy Log:** Click copy icon → Log copied to clipboard, toast notification
4. **Expand Details:** Click log entry → Expand to show full details/metadata
5. **Export Logs:** Click export → Dialog with format selection → Download file

### 8.2 Progress Interaction

**User Actions:**
1. **Pause:** Click pause → Confirmation dialog → Backtest pauses, time tracking continues
2. **Resume:** Click resume → Backtest continues from pause point
3. **Stop:** Click stop → Confirmation dialog → Backtest stops, results saved
4. **View Details:** Click details → Expandable panel with detailed metrics

### 8.3 Input Sheet Interaction

**User Actions:**
1. **Upload:** Drag-drop or click → File dialog → Validation → Preview
2. **Edit:** Click edit → Inline editing → Save changes
3. **Remove:** Click remove → Confirmation → File removed, form reset
4. **Use Template:** Click template → Template selection → Load template → Edit if needed

---

## 9. Accessibility & Performance

### 9.1 Accessibility Requirements

- **Keyboard Navigation:** Full keyboard support for all interactions
- **Screen Reader:** ARIA labels for all interactive elements
- **Color Contrast:** WCAG AA compliance (4.5:1 for text, 3:1 for UI components)
- **Focus Indicators:** Visible focus outlines for keyboard navigation
- **Error Messages:** Clear, descriptive error messages with suggestions

### 9.2 Performance Targets

- **Initial Load:** <2 seconds for log viewer with 1000 logs
- **Log Rendering:** <100ms for 1000 log entries
- **Progress Updates:** <16ms per frame (60 FPS)
- **File Upload:** <5 seconds for 10MB file validation
- **Memory Usage:** <100MB for typical backtest session

### 9.3 Responsive Design

- **Desktop:** Full feature set, multi-column layout
- **Tablet:** Adapted layout, touch-optimized controls
- **Mobile:** Simplified view, essential features only

---

## 10. Implementation Phases

### Phase 1: Foundation (Weeks 1-2)
- Log categorization system
- Basic log viewer with filtering
- Progress tracking (elapsed time, progress bar)

### Phase 2: Enhanced Logging (Weeks 3-4)
- Debug log toggle and display
- Live log streaming
- Log export functionality

### Phase 3: Input Integration (Weeks 5-6)
- File upload component
- Input sheet validation
- Template system fixes

### Phase 4: Advanced Features (Weeks 7-8)
- ETA calculation and display
- Background time tracking
- Advanced progress metrics

### Phase 5: Polish & Testing (Weeks 9-10)
- UI/UX refinements
- Performance optimization
- Accessibility improvements
- User acceptance testing

---

## Approval & Next Steps

**This specification is ready for review and approval.**

Upon approval, the development team will:
1. Create detailed technical specifications
2. Set up development environment and dependencies
3. Begin Phase 1 implementation
4. Establish testing protocols aligned with existing test plans

**Questions or modifications?** Please provide feedback before implementation begins.

---

**Document Status:** ✅ Ready for Approval  
**Last Updated:** February 22, 2026
