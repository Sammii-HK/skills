# Google Search Console — Chrome MCP Navigation Guide

Step-by-step instructions for automating GSC data collection via the Chrome browser extension.

## Initial Setup

1. Call `tabs_context_mcp` to get current tabs
2. Create a new tab if needed with `tabs_create_mcp`
3. Navigate to: `https://search.google.com/search-console/performance/search-analytics?resource_id=sc-domain:lunary.app`
   - For other properties, swap the resource_id accordingly
   - If the user isn't logged in, you'll see a Google sign-in page — let them know and wait

## Verifying You're on the Right Page

After navigation, take a screenshot and verify:
- The GSC interface is loaded (not a login page or error)
- The correct property is selected (check the property selector at top-left)
- You're on the "Search results" tab under Performance

If the property selector shows a different property, click it and select the correct one.

## Collecting Data for Each Time Window

Repeat this process for each of the four time windows: 3 months, 28 days, 7 days, 24 hours.

### Step 1: Set the Date Range

1. Find and click the **date range filter** at the top of the performance chart (it shows the current date range like "Last 3 months")
2. Use `find` or `read_page` to locate the date filter element
3. Select the appropriate preset:
   - "Last 3 months"
   - "Last 28 days"  
   - "Last 7 days"
   - "Last 24 hours" (may show as "Last day")
4. Click the date range option, then confirm/apply if needed
5. Wait for the data to reload — take a screenshot to verify

### Step 2: Capture Summary Metrics

1. Take a screenshot of the summary cards area at the top
2. Read the four metric cards:
   - **Total clicks** (and trend if shown)
   - **Total impressions** (and trend if shown)
   - **Average CTR** (and trend if shown)
   - **Average position** (and trend if shown)
3. Make sure all 4 metrics are enabled/visible — if CTR and Position cards appear greyed out, click them to toggle them on

### Step 3: Capture Top Queries

1. Below the chart, ensure the **Queries** tab is selected in the data table
2. Use `read_page` or `get_page_text` to extract the table data
3. If the table isn't fully readable via accessibility tree, use `javascript_tool` to extract table data:
   ```javascript
   // Extract the queries table data
   const rows = document.querySelectorAll('table tbody tr');
   const data = Array.from(rows).map(row => {
     const cells = row.querySelectorAll('td');
     return Array.from(cells).map(c => c.textContent.trim());
   });
   JSON.stringify(data.slice(0, 15));
   ```
4. Record the top 10-15 queries with: query text, clicks, impressions, CTR, position

### Step 4: Capture Top Pages

1. Click the **Pages** tab in the data table
2. Wait for it to load
3. Extract the same way as queries
4. Record the top 10-15 pages with: URL, clicks, impressions, CTR, position

### Step 5: Screenshot for Reference

Take a final screenshot of the current view for reference. This helps verify the data later.

## Handling Common Issues

### Table Data Not Readable
If `read_page` doesn't capture the table well, try:
1. `get_page_text` for raw text extraction
2. `javascript_tool` to query the DOM directly
3. Scrolling down if the table is partially off-screen

### Date Filter Not Found
The date filter is usually near the top of the page, showing text like "Last 28 days" or a date range. Try:
1. `find` with query "date filter" or "date range"
2. Look for elements containing "Last" text
3. Screenshot and visually locate it

### Data Still Loading
After changing date ranges or tabs, GSC can take a few seconds to load. Use:
```
computer action="wait" duration=3
```
Then screenshot to verify data has loaded before extracting.

### Metric Cards Not All Visible
By default, GSC may only show Clicks and Impressions. CTR and Position cards may be toggled off (they appear but are not highlighted/colored). Click on them to enable — they need to be active to see CTR and Position columns in the tables too.

## Navigation Shortcuts

| Destination | URL Pattern |
|------------|-------------|
| Performance (Search) | `search.google.com/search-console/performance/search-analytics?resource_id=sc-domain:{property}` |
| Performance (Discover) | `search.google.com/search-console/performance/discover?resource_id=sc-domain:{property}` |
| Coverage / Indexing | `search.google.com/search-console/index?resource_id=sc-domain:{property}` |
| Sitemaps | `search.google.com/search-console/sitemaps?resource_id=sc-domain:{property}` |

## Data Extraction Order

For efficiency, collect data in this order:
1. **3 months** (already default usually) → queries tab → pages tab → screenshot
2. **28 days** → change date → queries tab → pages tab → screenshot
3. **7 days** → change date → queries tab → pages tab → screenshot
4. **24 hours** → change date → queries tab → pages tab → screenshot

This minimizes tab switching and follows the natural flow from broad to narrow.
