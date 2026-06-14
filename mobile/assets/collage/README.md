# Live Dates collage photos

The Live Dates lobby empty-state (`lib/widgets/live_dates_collage.dart`) shows an
animated photo collage when no events are scheduled.

## How to add photos

Drop **JPG** images here named `1.jpg` through `12.jpg`:

```
assets/collage/1.jpg
assets/collage/2.jpg
...
assets/collage/12.jpg
```

The widget loads `1.jpg`…`12.jpg` and tiles them across 3 drifting columns.
You can ship fewer than 12 — any missing number falls back to a stylised warm
gradient tile automatically (no broken images), so the screen always looks good.

## Art direction (Ready to Marry)

Celebrate **African** connection across ages — youthful dates and couples,
friends and groups meeting up, plus mid-life and elder couples. Warm, joyful,
candid, real. Portrait/vertical crops work best (tiles are tall).

Recommended size: ~600×800 px each, optimised for mobile (< ~150 KB/photo).
