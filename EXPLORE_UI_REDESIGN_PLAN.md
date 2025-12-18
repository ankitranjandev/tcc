# Explore UI Redesign Plan

## Current Status
The Explore screen (HomeScreen) has been updated to use real APIs but the UI doesn't match the design in Frame 2186.png.

## Design Analysis (Frame 2186.png)

### Components Needed:

1. **Header Section**
   - ✅ Already exists in VaultScreen (Explore/Portfolio tabs)
   - Welcome message: "Welcome, Andrew"
   - Subtitle: "Explore and grow your wealth"

2. **TCC Coin Balance Card** (Blue Gradient)
   - Shows "TCC Coin" label
   - Large balance: "Le 7,340"
   - Small text: "$1 = 1 Coin"
   - White "Add Money" button on right

3. **Stats Cards Row**
   - **Yellow Card:** "Total Invested" with "Le 220,000"
   - **Green Card:** "Expected Return" with "Le 230,000"

4. **Invest in Foreign Currency Card**
   - Title: "1 Leone"
   - Value: "233 USD"
   - Small chart/graph
   - Green percentage: "+6.6 +0.11%"
   - Arrow icon on right

5. **Minerals Section**
   - Section title: "Minerals"
   - Subtitle: "Invest in rare minerals (e.g. Gold, Sil..."
   - Grid of cards:
     - Each card has:
       - Image (gold nuggets, silver, etc.)
       - Name (Gold, Silver, etc.)
       - Amount: "Le 2,217"
       - Green percentage: "+5% +6.6"
       - Small chart line

6. **Invest in Fixed Returns Banner**
   - Blue gradient background
   - Title: "Invest in Fixed Returns"
   - Icons on right side
   - Full width card

7. **Agro Business Section**
   - Title: "Agro Business"
   - Subtitle: "Invest in farming activity and all of the produce"
   - Two cards:
     - **Land Lease:** Image of farmland, "Le 2,217", "+5% +5.6"
     - **Processing:** Image of farmland, "Le 2,217", "+5% +6.1"

8. **Education Section**
   - Title: "Education"
   - Subtitle: "Invest in people's education and get huge profit"
   - Two cards:
     - **Institutions:** Image of building, "Le 2,217", "+5% +5.6"
     - **Dormitory:** Image of building, "Le 2,217", "+5% +6.1"

9. **Grow your Wealth Footer**
   - Title: "Grow your Wealth with TCC"
   - Decorative icons

## Major Changes Needed

### 1. Layout Structure
- **Current:** Simple vertical list
- **Needed:** Sections with images, charts, and complex card layouts

### 2. Missing Elements
- Images for investment cards
- Chart/graph components
- Complex card layouts with multiple data points
- Section headers with subtitles
- Grid layouts for minerals

### 3. Data Requirements
From the APIs, we need:
- Individual investment category data with:
  - Images/icons
  - Current value
  - Percentage change
  - Mini chart data
- Currency exchange rates
- More detailed portfolio breakdown

## Implementation Approach

### Option 1: Complete Redesign (Recommended)
Create a new HomeScreen matching the exact design with:
- All visual components from Frame 2186.png
- Real API data integration
- Image assets for each category
- Chart components for trends

### Option 2: Gradual Updates
Update sections incrementally:
1. Update balance card styling
2. Update stats cards styling
3. Add currency section
4. Add image-based category cards
5. Add section headers and formatting

## Required Assets

Need to add/create:
- Gold nugget image
- Silver image
- Other mineral images
- Farmland images
- School/institution images
- Dormitory images
- Chart/graph component or images
- Icons for various sections

## API Data Needed

Current APIs provide:
- ✅ Wallet balance
- ✅ Total invested
- ✅ Expected returns
- ✅ Investment categories

Still needed:
- ❌ Individual category values
- ❌ Percentage changes/trends
- ❌ Currency exchange rates
- ❌ Historical data for charts
- ❌ Category images/URLs

## Next Steps

1. Determine if you want exact UI match or simplified version
2. Source/create image assets for categories
3. Enhance backend APIs to provide:
   - Category-specific investment values
   - Trend/percentage data
   - Currency rates
4. Implement chart component or use static images
5. Rebuild HomeScreen with new layout

## Time Estimate

- **Full redesign:** Significant effort (complete rebuild)
- **Simplified version:** Moderate effort (keep structure, improve styling)
- **Current + API:** Already done ✅

## Recommendation

Given the complexity, I recommend:
1. Keep current API-integrated version
2. Gradually enhance UI elements
3. Add images as assets become available
4. Improve card styling to be closer to design

Or, if you want exact match:
1. Provide all image assets
2. Confirm backend can provide detailed category data
3. Complete UI redesign (will take substantial time)
