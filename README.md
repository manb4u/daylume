# daylume

A Bauhaus-inspired weather calendar for the web. Every day in the month view shows its weather — sunny, cloudy, rain, snow — built from simple circles, squares and triangles. Tap a day for a focused view. The interface turns light at sunrise and dark at sunset, following the real sun at the location you're viewing.

- **One year of history** (recorded weather), a **16-day forecast** with hourly detail, and a **1-month outlook**
- **Saved places** to switch between cities in one tap
- No account, no API key, no build step: it's a single `index.html`

---

## Open daylume

daylume needs a normal web address (`https://` or `http://localhost`) for location access to work. Pick one of these:

### Option 1 — GitHub Pages (recommended)

1. In this repository, go to **Settings → Pages**.
2. Under **Build and deployment**, set **Source** to *Deploy from a branch*, choose **`main`** and **`/ (root)`**, then **Save**.
3. After a minute, your app is live at **`https://manb4u.github.io/daylume/`**. Open it on any device, and bookmark it or add it to your home screen.

### Option 2 — Run it on your computer

From the project folder, start any simple web server, then open the address it prints:

```bash
python3 -m http.server 8000
# then visit http://localhost:8000
```

### Option 3 — Open the file directly

Double-clicking `index.html` works for browsing weather, but most browsers block location access for local files. Use the city search instead, or use option 1 or 2.

---

## Allow location access

The first time you open daylume, your browser asks: **“Allow daylume to use your location?”**

- Choose **Allow** to see weather for where you are. Your coordinates are only used to fetch weather and the name of your city (see [Privacy](#privacy)).
- Choose **Block** and daylume shows **Berlin** instead. You can always search for any city.

daylume only asks when it has nothing else to show: once you've viewed or saved a place, it opens that place directly.

### Changed your mind?

| Browser | How to change location permission |
|---|---|
| **Chrome / Edge** (desktop) | Click the icon left of the address bar → **Site settings** → **Location** → *Allow*, then reload. |
| **Safari** (Mac) | **Safari → Settings → Websites → Location** → set the site to *Allow*, then reload. |
| **Firefox** | Click the icon left of the address bar → clear the blocked **Location** permission, then reload. |
| **iPhone / iPad** | **Settings → Privacy & Security → Location Services** must be on, and **Safari Websites** set to *While Using the App*. Then in Safari tap **aA → Website Settings → Location → Allow**. |
| **Android (Chrome)** | Tap the icon left of the address bar → **Permissions → Location → Allow**. Also make sure location is on in the phone's quick settings. |

To make daylume ask again from scratch, clear the site's data (see [Reset daylume](#reset-daylume)).

---

## Using daylume

### Month view
- Each day shows a weather symbol, the **high** (large) and **low** (small) temperature, and either the chance of rain, recorded rainfall (mm), snowfall (cm) or a blue **Frost** marker when the low is at or below 0°.
- Snow days get an icy tint and a white band at the bottom that grows with the amount of snow.
- Days from the next month that spill into the grid get a diagonal hatch pattern; it disappears once you move to that month.
- Hover a day to see its weather symbol move: the sun pulses, clouds drift, rain and snow fall, lightning flickers. **Today's** symbol is always animated.
- **Today** has a red circle. Use **‹ ›** to move between months and **Today** to jump back.

### What the days mean
| Days | Source | Shown as |
|---|---|---|
| Up to 1 year ago | Recorded weather archive | Actual highs, lows, rain and snow |
| Last few days → 16 days ahead | Live forecast | Hourly detail, chance of rain, UV |
| 16 days → 1 month ahead | Outlook from 31 model runs | **≈** before the temperature |

### Focused day view
Click or tap any day to open it.
- The large weather symbol is **animated on a loop** — the same motion you see when hovering a day, but always on.
- The bottom of the left panel shows a small looping **penguin scene** for the day's weather:
  - **Sunny / partly cloudy**: sunbathing in sunglasses on a towel under a beach umbrella, on sand (shows the UV index)
  - **Cloudy**: fast asleep in bed under a red blanket, nightcap on, with Zzz drifting up, on a wooden floor (wind)
  - **Rainy**: sitting in a little yellow boat under an umbrella, rocking gently and drifting right to left on the water while rain falls and ripples spread (rain in mm)
  - **Snow**: skiing with goggles, scarf and poles over frosted ice (snowfall in cm; the ice deepens with more snow)
  - **Sleet**: walking in a quilted winter jacket and beanie over frosted ice
  - **Storm**: walking through heavy rain until lightning strikes — a flash, an x-ray flicker — and walking off as a skeleton, on a road
  - **Fog**: driving a little yellow car left to right along a road while fog banks drift past (wind)
  All scenes loop continuously and hold still if your device is set to reduce motion.
- **Hourly chart**: temperature line, rain bars and the daylight hours. Today shows a red **NOW** marker.
- **Tiles**: sunrise and sunset, daylight length, precipitation or snowfall, wind, UV (or *Wet hours* for past days) and the temperature range.
- **Outlook days** show a *Model spread* chart instead: each dot is one model run, the bar is the average, and a **Confidence** tile tells you how much the runs agree.
- Move between days with the **‹ ›** buttons or the **← →** keys. Press **Esc** or the **×** to close.
- Share a day by adding its date to the address, for example `…/daylume/#2026-12-24`.

### Search and saved places
- Type a city in **Search a city**. Click a result to preview it, or press **Save** to keep it without leaving the current city.
- In the sidebar, the **Save** button (yellow) keeps the city you're viewing. It turns black once saved.
- Click the **city name** in the sidebar to open your saved places, each with its current temperature and local time. Pick one to switch.
- **Manage** opens all your places as cards. Each card is light or dark depending on whether it's day or night there. Make one your **Home** (it opens first) or remove it with **×**.

### Sun and moon
- By day the sidebar shows the **sun** travelling its arc between sunrise and sunset.
- After sunset the arc stays dashed and the **moon** appears above the horizon, drawn at its current phase — new, crescent, quarter, gibbous or full; lit on the right while waxing and on the left while waning (mirrored in the southern hemisphere). The heading names the phase.
- Sunrise and sunset times stay below the arc, with how much of the moon is lit in between, and the date of the next full or new moon underneath.
- Moon phases are calculated in the app from standard astronomical formulas (Meeus), so they work for any city and date. They match the US Naval Observatory to within a few minutes.

### Day and night theme
- daylume switches to **light** at local sunrise and **dark** at local sunset, at the location you're viewing. The chip at the top right shows the next change.
- Click the chip to choose: **Auto → Light → Dark → Auto**.

### Units
Switch between **°C** and **°F** at the top right.

---

## Privacy

- **No accounts, no tracking, no cookies.**
- Your saved places, last viewed city, unit and theme choice are stored only in **your browser** (local storage). They don't sync between devices.
- To show weather, daylume sends the coordinates of the place you're viewing to these free services:
  - [Open-Meteo](https://open-meteo.com) for forecasts, history, the outlook and city search
  - [BigDataCloud](https://www.bigdatacloud.com) only once, to turn your own location into a city name

## Reset daylume

Clearing the site's data removes your saved places and settings and makes daylume ask for location again:

- **Chrome / Edge**: icon left of the address bar → **Site settings** → **Delete data**
- **Safari (Mac)**: **Settings → Privacy → Manage Website Data** → find the site → **Remove**
- **Firefox**: icon left of the address bar → **Clear cookies and site data**
- **iPhone / iPad**: **Settings → Apps → Safari → Advanced → Website Data** → swipe to delete the site

## Troubleshooting

| Problem | Fix |
|---|---|
| It shows Berlin, not where I am | Location was blocked or unavailable. Allow it (see above), or search for your city and press **Save**. |
| The location prompt never appears | You're opening the file directly, or location was blocked earlier. Use GitHub Pages or `localhost`, then check the site's permission. |
| “Past-year history” or “1-month outlook is unavailable” | One of the weather services didn't respond. The forecast still works; reload in a few minutes. |
| Days show “Beyond outlook” or “Before history” | Weather is available from 1 year ago up to 1 month ahead. |
| Nothing loads | daylume needs an internet connection. Check you're online and reload. |

---

Weather data by [Open-Meteo](https://open-meteo.com) (CC BY 4.0).
