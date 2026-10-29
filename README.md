# Timeline

A cute timeline-style calendar app for iPhone, written in SwiftUI with SwiftPM and built **on Linux** with [xtool](https://github.com/xtool-org/xtool). No Xcode GUI needed.

## Features
- Today's events from the iPhone calendar (EventKit) on a vertical timeline with a live current-time line
- Horizontal day paging that never ends, with whole-page snapping
- A week strip that pages week by week, also without end
- A Week view with the dates stacked down the left, which pages vertically by week
- A Month view with a calendar grid, event dots and the selected day's events, paging vertically by month without end
- A Year view with a 3-column grid of mini months (today highlighted, a dot on days with events), paging vertically by year without end; tap a month to open it in Month view
- The selected week's date bubbles fly between the strip, the week column and the month grid when you switch Day/Week/Month
- A Today toolbar button that fades between enabled and disabled (in Year view it jumps to the current year)
- A pastel theme and app icon

## Project structure
```
Sources/Hello/
├── App/TimelineApp.swift          # @main entry, injects CalendarStore
├── Model/
│   ├── CalendarStore.swift        # EventKit access, per-day cache, range loading
│   ├── ViewMode.swift             # Day / Week / Month / Year (+ debug TIMELINE_MODE launch env)
│   ├── WeekIndex.swift            # week offsets used as pager page ids
│   ├── MonthIndex.swift           # month offsets, month grid days
│   └── YearIndex.swift            # year offsets, months of a year
├── Support/Paging.swift           # withoutAnimation, PageWindow (infinite pagers)
├── Theme/                         # pastel palette, event emoji
└── Views/
    ├── ContentView.swift          # composition + Day/Week switch
    ├── Components/                # header, bottom bar, date bubble, bubble flight overlay
    ├── Day/                       # day pager, timeline grid, event blocks, all-day strip
    ├── Week/                      # week strip pager, vertical week view, week rows
    ├── Month/                     # month pager, grid, cells with event dots, selected-day cards
    ├── Year/                      # year pager, year page, mini months
    └── States/                    # loading, empty, access denied
```

## Build and run
```sh
xtool dev build --sign             # debug (default)
xtool dev build -c release --sign  # release
```
Debug builds read `TIMELINE_MODE=day|week|month|year` from the launch environment to open in that view (for screenshots), e.g.
`pymobiledevice3 developer dvt launch --rsd ADDR PORT --env TIMELINE_MODE=year <bundle id>`.
The app was installed over Tailscale with [pymobiledevice3](https://github.com/doronz88/pymobiledevice3), following [omarchy-apple-dev](https://github.com/joshuaswarren/omarchy-apple-dev).
