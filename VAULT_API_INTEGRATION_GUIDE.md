# Vault Section API Integration Guide

## Issues Found

The Vault > Explore section (HomeScreen) is using mock data instead of real backend APIs.

## Changes Required

### 1. Remove MockDataService

**Current (Line 25-26):**
```dart
final mockService = MockDataService();
final stats = mockService.dashboardStats;
```

**Replace with:** API calls in initState() or FutureBuilder

### 2. Fetch Real Wallet Balance

**Current (Line 95):**
```dart
currencyFormat.format(user?.walletBalance ?? 0)
```

**Replace with:** Data from `WalletService().getBalance()`

### 3. Fetch Real Investment Stats

**Current (Lines 194-210):**
```dart
_buildStatCard(
  'Total Invested',
  currencyFormat.format(stats['totalInvested']),
  ...
),
_buildStatCard(
  'Expected Return',
  currencyFormat.format(stats['expectedReturns']),
  ...
),
```

**Replace with:** Data from `InvestmentService().getPortfolio()`

### 4. Fetch Real Investment Categories

**Current (Lines 234-266):** Hardcoded investment cards

**Replace with:** Dynamic list from `InvestmentService().getCategories()`

## Implementation Steps

1. Convert HomeScreen to use FutureBuilder or state management
2. Add loading states
3. Add error handling
4. Fetch data from:
   - `/wallet/balance`
   - `/investments/portfolio`
   - `/investments/categories`

## Backend API Endpoints

- `GET /wallet/balance` - Returns wallet balance and currency
- `GET /investments/portfolio` - Returns user's investments with total invested and expected returns
- `GET /investments/categories` - Returns available investment categories (Agriculture, Minerals, Education, etc.)
