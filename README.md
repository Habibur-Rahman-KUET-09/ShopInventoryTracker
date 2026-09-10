# দোকান হিসাব (Dokan Hisab)

Shop Sales & Inventory Tracker — a Bangla-language Flutter app for small
Bangladeshi shop owners (grocery, pharmacy, stationery, cosmetics, etc.) to
track daily sales, stock, profit/loss, and customer credit (বাকি), based on
the v0 demo scope.

## Features

- **দৈনিক বিক্রি এন্ট্রি** — Multi-item sale entry with automatic totals.
- **স্টক ম্যানেজমেন্ট** — Add/edit products (buy price, sell price, quantity)
  with automatic stock deduction on sale and low-stock highlighting.
- **লাভ-ক্ষতি ড্যাশবোর্ড** — Daily/weekly/monthly sales & profit summary with
  a trend chart and a top-selling-products list.
- **বাকি হিসাব** — Track customer credit balances, add dues, and record
  payments against a running ledger per customer.
- Fully Bangla UI, mobile-first layout, minimal-click entry flows.

## Tech stack

- **Flutter** (Material 3) for the UI.
- **Hive** for on-device local storage (no backend required for the demo,
  matching the v0 scope; a real backend such as Firebase/Supabase can be
  added later without changing the UI layer).
- **Provider** for state management.
- **fl_chart** for the sales trend chart.

## Project structure

```
lib/
  models/          Product, Sale, SaleItem, DueCustomer, DueTransaction
  repositories/     Hive-backed persistence for each model
  providers/         ChangeNotifier state holders (business logic)
  screens/            One file per screen
  widgets/            Shared UI components (e.g. StatCard)
  utils/              Formatters (currency, date)
  theme/              App-wide Material theme
```

## Running

```bash
flutter pub get
flutter run
```

## Testing

```bash
flutter analyze
flutter test
```

Tests cover model logic (stock, profit, due balance calculations) and full
UI flows (adding a product, completing a sale, recording a due payment).
