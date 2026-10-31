# KRM Kirana App — UI/UX Bug Report

**Scope:** `app/` (Flutter client, 150 Dart files, ~19k lines) · **Date:** 2026-10-30
**Target:** Android phones (320–430 dp, cheap devices), also builds web/desktop
**Method:** full read of every screen, sheet and shared widget; every finding below was re-checked against the source and the code line quoted is verbatim. `flutter analyze` passes clean, so none of these are lint findings — they are runtime, layout, data-honesty and interaction defects.

## Summary

| Severity | Count | Meaning |
|---|---|---|
| **P1** | 18 | Money/ledger wrong, data silently lost, crash, or UI that lies about what it did |
| **P2** | 14 | Noticeable friction: keyboard covers buttons, dead controls, overflow at large fonts |
| **P3** | 16 | Polish: consistency, a11y nits, misleading copy |

**48 findings total.** *IDs are stable references for the fix phase, not sequential — UX-42+ were found in a second pass.*

**Headline problems**

1. **Several features only pretend to work** — contact import shows 12 invented people, Backup & Restore fakes a backup, language switch changes nothing, "Hold Sale" holds nothing, product settings/search are SnackBar no-ops.
2. **Udhar (credit) payments and imported customers are not persisted** — the balance drops on screen, then comes back after pull-to-refresh.
3. **Voiding a bill is cosmetic** — badge changes locally, server and totals still count the bill.
4. **Demo/placeholder data leaks into real product screens** — fabricated "Rs. 2,000" purchase price, "(Rs. 20/kg)", "GRN001", "(1 Bora)".
5. **The app has no error state at all** — if the backend is down, every screen shows zeros/empty lists exactly like a quiet day, with no retry.
6. **Money formatting is inconsistent** — the same bill shows `Rs. 1234.50` in checkout and `Rs. 1234` on the receipt, and printed tax is always `0`.

---

## P1 — fix these first

### UX-01 · Udhar payment is never saved
`features/parties/presentation/screens/parties_screen.dart:334`
```dart
_customers[idx] = _customers[idx].copyWith(udharBalance: newBal);
```
**Symptom:** "Received Rs. 500 from Sita" appears and the balance drops, but nothing is sent to the server and no ledger row is created — the udhar is back after pull-to-refresh or app restart.
**Cause:** The screen mutates the repository's list in place. `AppDataRepository.receiveUdharPayment()` (line 418) — which persists, inserts a transaction and notifies listeners — is never called.
**Fix:** Replace the `setState` mutation with `await AppDataRepository.instance.receiveUdharPayment(...)` using the sheet result.

### UX-02 · Customer imported from contacts is never saved
`features/parties/presentation/screens/parties_screen.dart:319`
```dart
setState(() => _customers.insert(0, newCustomer));
```
**Symptom:** The new customer shows in the list, disappears on refresh, and never reaches the backend.
**Cause:** Result pushed into the in-memory list instead of `addCustomer` (which the sibling `_addNewCustomer` at line 289 does correctly).
**Fix:** `await AppDataRepository.instance.addCustomer(newCustomer);` before the SnackBar.

### UX-03 · "Import from Contacts" shows 12 invented people
`features/customers/presentation/sheets/pick_contact_sheet.dart:19`
```dart
PhoneContact(name: 'Aayush Karki', phone: '9841987654'),
```
**Symptom:** A sheet titled "Choose from device address book" lists 12 hardcoded strangers. Picking one creates a real customer with a fake name/phone on the shop's ledger.
**Cause:** `defaultContacts` const list is rendered; the device contact API is never read.
**Fix:** Read real contacts (`flutter_contacts`) or remove the entry point and label until implemented.

### UX-04 · Supplier edits are silently discarded
`features/parties/presentation/screens/parties_screen.dart:828`
```dart
onMoreOptions: () => AddEditSupplierSheet.show(context, supplier: supplier),
```
**Symptom:** Editing a supplier from the Parties list opens the sheet, saves, and the card never changes.
**Cause:** The returned `Supplier?` is never awaited and `updateSupplier` (repository line 491) is never called.
**Fix:** `onMoreOptions: () async { final u = await AddEditSupplierSheet.show(...); if (u != null) await AppDataRepository.instance.updateSupplier(u); }`.

### UX-05 · Voiding a bill changes nothing
`features/sales/presentation/screens/transaction_details_screen.dart:196`
```dart
setState(() => _isCancelled = true);
```
**Symptom:** "Bill #X marked as Cancelled/Void" + a CANCELLED badge, but reopening shows PAID IN FULL, and the amount still counts in today's sales.
**Cause:** Only a local boolean; `voidBill()` (repository line 818) is never called. Same gap in `today_bills_screen.dart:243` — `BillActionType.cancel` has no branch at all, so "Cancel & Return Bill" just closes the sheet (no confirmation, no message).
**Fix:** Confirm → `await AppDataRepository.instance.voidBill(widget.receiptNumber, reason)` → refresh; add the missing `cancel` branch in `today_bills_screen`.

### UX-06 · Printed/shared receipt always shows tax as 0
`features/sales/presentation/sheets/sale_success_sheet.dart:51`
```dart
tax: 0.0,
```
**Symptom:** Customer paid VAT and delivery charges, but the printed receipt has `Tax / VAT  Rs. 0`, so `subtotal − discount + tax ≠ grand total`.
**Cause:** `_toInvoiceData` hardcodes 0; `SaleRecord`/`completeSale` never carry the tax or additional charges from checkout. `printing_service.dart:372` prints whatever is in `data.tax`.
**Fix:** Persist `_taxAmount`/`_additionalCharges` on `SaleRecord` and print them.

### UX-07 · Placeholder financial data shown as real
`features/products/presentation/screens/product_details_screen.dart:686`
```dart
mainValue: _product.purchasePrice > 0 ? _product.formattedPurchasePrice : 'Rs. 2,000',
```
**Symptom:** A product with no cost price displays "Purchase Price Rs. 2,000"; every product gets a fabricated "(Rs. 20/kg)" profit sub-value (line 701), plus "GRN001" as SKU (596), "Clean, long grain and good aroma." as description (626) and "(1 Bora)" as pack size (659, 996). Shopkeepers read these as real numbers.
**Cause:** Mockup placeholders never replaced with empty states.
**Fix:** Render `—` / "Not set" for zero/empty values and drop the fabricated sub-values.

### UX-08 · Barcode Labels silently preselects 16 labels
`features/products/presentation/screens/barcode_products_screen.dart:36`
```dart
_selectedProductCopies[allProducts[i].id] = 2;
```
**Symptom:** Opening the screen preselects the first 8 products at 2 copies each (the comment says 5), so the already-enabled Print button emits 16 labels nobody chose — wasted label stock.
**Cause:** `initState` pre-fills the selection map "for convenience".
**Fix:** Start empty; require explicit selection before Print.

### UX-09 · Date picker crashes for already-expired stock
`features/products/presentation/sheets/date_picker_sheet.dart:62`
```dart
firstDate: now,
```
**Symptom:** Editing a product whose expiry is in the past and tapping "Calendar" throws the `showDatePicker` assertion (`initialDate` before `firstDate`) instead of opening the picker.
**Cause:** `initialDate: _selectedDate` may predate `firstDate: now`.
**Fix:** `firstDate: initialDate != null && initialDate!.isBefore(now) ? initialDate! : now`.

### UX-10 · Onboarding reports success even when saving failed
`features/onboarding/presentation/screens/shop_onboarding_screen.dart:134`
```dart
} catch (_) {
```
**Symptom:** The "Store Setup Complete" celebration always shows, even if the shop name/logo PUT failed — the shop stays unnamed on the server with no indication.
**Cause:** Catch swallows every error, then `SetupCompleteSheet.show` runs unconditionally after it.
**Fix:** Capture failure, show an error, keep the form (button re-enabled) instead of the success sheet.

### UX-11 · POS "Apply Discount" and "Hold Sale" are dead
`features/sales/presentation/screens/sales_screen.dart:112`
```dart
await ApplyDiscountSheet.show(context, subtotal: subtotal);
```
**Symptom:** Applying a discount from the POS ⋮ menu returns to an unchanged cart total, so the customer is charged full price after agreeing to a discount. "Add Note" (115) also discards its result, and "Hold Sale" (117-121) only shows a SnackBar — no sale is held.
**Cause:** Return values ignored; the POS screen keeps no discount/note state.
**Fix:** Capture `DiscountResult` and apply it to the cart total (or delete the menu entries); implement hold-sale storage or remove the item.

### UX-12 · Custom date range filter is ignored
`features/sales/presentation/screens/transactions_screen.dart:179`
```dart
if (_dateRangeLabel == 'Today') {
```
**Symptom:** Picking "14 Oct – 20 Oct" (label built at line 260) still lists every transaction ever recorded.
**Cause:** Filtering only branches on the literal strings `'Today'`/`'Yesterday'`; a custom range falls through as "no filter".
**Fix:** Store `DateTime? _rangeFrom/_rangeTo` and filter `tx.timestamp` between them.

### UX-13 · No error state anywhere; server failure looks like zero sales
`features/dashboard/presentation/screens/dashboard_screen.dart:159`
```dart
if (repo.isLoading && repo.products.isEmpty && repo.todayBills.isEmpty) {
```
**Symptom:** With the backend unreachable, Home shows `Rs. 0.00` and zeros for every stat — indistinguishable from a zero-sales day — and lists show "No transactions found", with no retry anywhere.
**Cause:** Only a loading branch exists. `AppDataRepository.lastError` is captured (line 45) but never rendered by any screen (only `add_product_screen` uses it).
**Fix:** Add an error branch keyed on `lastError` when cache is empty, with a Retry button (`refreshAll`).

### UX-14 · "Backup & Restore" fakes a backup
`features/more/presentation/screens/more_screen.dart:161`
```dart
content: Text('Offline database snapshot verified and cached locally'),
```
**Symptom:** Tapping Create Backup shows a success message, but nothing is backed up (it only re-fetches data). Users may trust this as their data safety net.
**Cause:** `createBackup` calls `refreshAll()` and reports success.
**Fix:** Implement a real export (JSON/SQLite dump to file/share) or label the tile "Offline cache" and say plainly that no backup is made.

### UX-15 · Language & currency switch does nothing
`app/lib/main.dart:23` + `features/more/presentation/screens/more_screen.dart:51`
```dart
return MaterialApp(
```
**Symptom:** Choosing "नेपाली (Nepali)" or "NPR" shows "Preferences set to Nepali (NPR)", but every screen stays English with `Rs.`, and the choice is forgotten when the app restarts.
**Cause:** `MaterialApp` has no `locale`, `localizationsDelegates` or `supportedLocales` (zero occurrences in `lib/`), no strings are localized, and `_preferences` is in-memory state that nothing consumes.
**Fix:** Either wire real i18n (`flutter_localizations` + shared preference + `Locale`) or hide the option. At minimum persist the selection and apply the currency symbol formatter.

### UX-16 · A half-built sale is destroyed with no warning
`features/sales/presentation/screens/sales_screen.dart:295`
```dart
Navigator.pop(context);
```
**Symptom:** System Back, or tapping another bottom-nav tab (297/303/309 `pushReplacement`), throws away the cart with no confirmation — the cashier loses the sale and must re-scan everything.
**Cause:** Cart lives only in `_SalesScreenState`; there is no `PopScope` anywhere in the app except `party_details_screen.dart:366`.
**Fix:** Wrap the Scaffold in `PopScope(canPop: _cartItems.isEmpty, ...)` with a "Discard sale?" confirm, and move tab switching off `pushReplacement`.

### UX-42 · Login errors show raw developer text
`core/network/api_client.dart:144`
```dart
return ApiResponse.failure(message: 'Network error: $e', statusCode: 500);
```
**Symptom:** A failed login shows a red SnackBar with `ClientException with SocketException: Connection refused (OS Error…)`; the offline branch right above it (line 138) tells the shopkeeper to check whether a "Docker container is running".
**Cause:** The catch-all interpolates the exception into the user-facing message, and `login_screen.dart:92` / `register_screen.dart:102` print `res.message` verbatim.
**Fix:** Fixed user-facing copy ("Can't reach the server. Check your connection and try again.") and log `$e` instead.

### UX-43 · OTP sheet can be dismissed, stranding an unverified account
`features/auth/presentation/screens/register_screen.dart:86`
```dart
VerifyOtpSheet.show(
```
**Symptom:** After registering, a stray tap outside the OTP sheet (or a swipe down) closes it. The user is left on the filled register form with an account that is not verified; pressing "Create Account" again only returns "already registered", and there is no way to reopen verification.
**Cause:** `verify_otp_sheet.dart:26` uses the default `isDismissible: true` / `enableDrag: true`, and the `Future<bool?>` returned here is never awaited, so the caller cannot detect the abandonment.
**Fix:** Pass `isDismissible: false, enableDrag: false` (the sheet already has its own Cancel), or await the result and re-offer a "Verify email" action.

---

## P2 — visible friction

### UX-17 · Keyboard hides the payment button on small phones
`features/sales/presentation/sheets/cash_payment_sheet.dart:88`
```dart
child: Column(
```
**Symptom:** On a 5" phone the cash sheet's ~470 dp of content plus the keyboard overflow, hiding "Change to Return" and "Complete Cash Sale".
**Cause:** Non-scrollable `Column`; `viewInsets` is added as padding but the body cannot scroll. Same pattern in `apply_discount_sheet`, `add_tax_sheet`, `additional_charges_sheet`, `partial_payment_sheet`, `receive_udhar_payment_sheet`, `record_purchase_sheet`.
**Fix:** Wrap each body in `SingleChildScrollView` (as `edit_cart_item_sheet` already does).

### UX-18 · Setup-complete sheet traps the user on short screens
`features/onboarding/presentation/sheets/setup_complete_sheet.dart:105`
```dart
child: Column(
```
**Symptom:** On ~480–568 dp tall phones the ~600 dp sheet overflows and "Add Your First Product" is clipped; the sheet is `isDismissible: false, enableDrag: false`, so there is no way out.
**Cause:** Non-scrollable `mainAxisSize.min` Column in a non-dismissible sheet.
**Fix:** Make the body scrollable and keep one always-reachable primary action.

### UX-19 · The notification bell is permanently red
`features/dashboard/presentation/widgets/dashboard_header.dart:15`
```dart
this.hasUnreadNotifications = true,
```
**Symptom:** The red dot shows on every visit, even for a new shop whose Notifications screen says "No notifications", and it never clears after "Mark all read".
**Cause:** Defaults to `true` and no caller passes a real count; the notifications screen rebuilds every item with `isRead: false` on each visit (`notifications_screen.dart:47/60/73`), so read state is lost too.
**Fix:** Derive from an unread count, persist read state (or mark read server-side), pass it into `DashboardHeader` from both callers.

### UX-20 · Two prominent buttons do nothing
`features/dashboard/presentation/screens/dashboard_screen.dart:120` → `'$action tapped'` SnackBar (line 77).
`features/products/presentation/screens/products_screen.dart:117` → `Text('Product Settings tapped')`.
**Symptom:** The Home search icon and the Products settings icon are visible primary controls that answer with "tapped".
**Fix:** Wire them to real screens (a global search exists in spirit: reuse `ProductSearchBar`/transactions search) or remove the icons.

### UX-21 · Notification action pills are inert
`features/notifications/presentation/screens/notifications_screen.dart:429`
```dart
item.actionLabel!,
```
**Symptom:** "Restock", "View Bill", "Collect" pills look tappable; tapping only toggles read state.
**Cause:** Painted in a plain `Container` with no `onTap`.
**Fix:** Wrap in `InkWell` and navigate to the product/bill/party.

### UX-22 · "Call" copies the number instead of dialing
`features/parties/presentation/screens/party_details_screen.dart:145`
```dart
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Phone $phone copied to clipboard.')));
```
**Symptom:** The phone icon and the "Call" pill never dial; they silently put the number on the clipboard.
**Fix:** `launchUrl(Uri.parse('tel:$phone'))`, or relabel the control "Copy number".

### UX-23 · Money renders differently on every screen
`features/sales/presentation/screens/transaction_details_screen.dart:656`
```dart
'Rs. ${widget.totalAmount.toInt()}',
```
**Symptom:** The same Rs. 1,234.50 bill reads `Rs. 1234` (truncated) on details vs `Rs. 1,234.50` in checkout; Home shows the total with paisa but cash/card/udhar without (`dashboard_screen.dart:236-239`), so the parts don't visibly add up.
**Cause:** `.toInt()` truncation at 8 more lines (584, 594, 621, 626, 634, 717, 727, 737) mixed with `toStringAsFixed(2)` and `NumberFormat('#,##0.00')`.
**Fix:** One shared `formatMoney()` helper (2 decimals only when non-zero, grouped) used everywhere, including receipts.

### UX-24 · Tax label is hardcoded to 13%
`features/sales/presentation/screens/transaction_details_screen.dart:633`
```dart
'VAT / Tax (13%)',
```
**Symptom:** Shown even when the bill had no tax or a different rate.
**Fix:** Pull the rate from the transaction (or hide the row when `taxAmount == 0`).

### UX-25 · Add/Edit Product loses work on back; expiry cleared by Cancel
`features/products/presentation/screens/add_product_screen.dart:314`
```dart
onPressed: () => Navigator.of(context).pop(),
```
**Symptom:** Back (or system back) discards a half-filled product form with no prompt. Related: at line 185 `_expiryDate = selected;` runs even when the date sheet is cancelled, silently wiping an existing expiry date.
**Fix:** `PopScope` + dirty check; only assign `_expiryDate` when the sheet returns a real result (distinguish "clear" from "cancel").

### UX-26 · Low-stock threshold saves 0 silently
`features/products/presentation/sheets/low_stock_alert_sheet.dart:93`
```dart
threshold: _threshold,
```
**Symptom:** Clearing the field stores 0 with no error, permanently disabling low-stock alerts for that product.
**Fix:** Validate `> 0` with an inline error before popping.

### UX-27 · Barcode scanner overflows when typing a code
`features/products/presentation/sheets/barcode_scanner_sheet.dart:141`
```dart
height: 240,
```
**Symptom:** Opening the keyboard for "enter manually" overflows the sheet on small phones and pushes Add off-screen.
**Fix:** Scrollable body, or shrink the camera preview when `viewInsets.bottom > 0`.

### UX-28 · Low-stock card row overflows at large fonts
`features/products/presentation/screens/low_stock_screen.dart:736`
```dart
'Deficit: ${item.deficit.toInt()} ${p.stockUnit} needed',
```
**Symptom:** This Text and "Est. Restock: Rs. …" are unconstrained siblings in a `spaceBetween` Row — RenderFlex overflow on 320 dp screens or with enlarged system font.
**Fix:** `Flexible` + ellipsis on both, or stack them.

### UX-29 · Primary POS "+" button is a 26 dp target
`features/sales/presentation/widgets/pos_product_card.dart:136`
```dart
width: 26,
```
**Symptom:** The add-to-cart control on every product tile is 26×26 dp with no label — mistaps add the wrong product. (`category_filter_chips.dart:23` chips are 30 dp tall for the same reason; `AppTopBar` back button is 44 dp.)
**Fix:** ≥44–48 dp hit area with `Tooltip('Add to cart')` / `Semantics(button: true)`.

### UX-44 · Password reset sheet clips at the top when the keyboard opens
`features/auth/presentation/sheets/forgot_password_sheet.dart:158`
```dart
child: Column(
```
**Symptom:** On a small phone the sheet body (drag handle, heading, email field, button) is pushed above the visible area by `viewInsets.bottom` and clipped — the heading and sometimes the field disappear, with no way to scroll.
**Cause:** Non-scrollable `mainAxisSize.min` Column inside a `viewInsets.bottom` padding; the sheet cannot shrink or scroll.
**Fix:** Wrap the Column in `SingleChildScrollView`, keeping the existing inset padding.

---

## P3 — polish & consistency

| ID | Location | Issue |
|---|---|---|
| UX-30 | whole app | **Zero** `Tooltip(` / `Semantics(` usages in 150 files — every icon-only control (bell, search, eye toggle, ⋮, back, +) is unlabeled for TalkBack. |
| UX-31 | `dashboard_screen.dart:60`, `more_screen.dart:76` | `parts[1][0]` throws `RangeError` for a name with a double space ("Ram  Shrestha") → red screen on profile load. |
| UX-32 | `checkout_sheet.dart:856` | "Proceed to Payment" has no in-flight guard; a double tap can open two payment sheets / create two bills. |
| UX-33 | `cart_bottom_bar.dart:21` | Counts cart *lines*, not quantities: "2 items in cart" for 12 packets. |
| UX-34 | `login_screen.dart:416`, `register_screen.dart:251` | Footer `Row` with two unflexed `Text`s overflows at ~1.3× font scale. |
| UX-35 | `today_bills_screen.dart:239`, `print_barcode_sheet.dart:387` | Raw exception text (`Print failed: $e`) shown to the cashier. |
| UX-36 | `image_crop_sheet.dart:449` | Aspect/zoom/rotate/crop only change the preview; Save returns the untouched original. |
| UX-37 | `more_screen.dart:751`, `printer_settings_screen.dart:162` | Printer shows "• Ready" / "Ready to print" unconditionally, with no printer connected. |
| UX-38 | `auth_text_field.dart` | No `autofillHints` anywhere in the app → password managers and OTP autofill don't work. |
| UX-39 | `login_screen.dart:133` | Google sign-in cancel detected by comparing the exact message string `'Google sign-in was cancelled.'` — any wording change shows a scary red error on a normal cancel. |
| UX-40 | `category_picker_sheet.dart:135` | "Add" with an empty custom-category field does nothing at all (no message, sheet stays open). |
| UX-41 | `sales_screen.dart:243`, `products_screen.dart:267` | Empty state says "No products found in inventory" even when a search/filter simply matched nothing. |
| UX-45 | `register_screen.dart:124` | Back arrow / system back discards a fully filled registration form (name, email, shop, phone, password) instantly, no confirm. |
| UX-46 | `country_picker_sheet.dart:190` | Selection is matched by dial code, so both United States and Canada (`+1`) show as selected; the sheet also never pads for `viewInsets`, so the keyboard covers results. |
| UX-47 | `login_screen.dart:194` | The Email/Phone segmented toggle is ~36 dp tall and exposes no selected state to TalkBack (`Semantics(selected:)` missing). |
| UX-48 | `app_primary_button.dart:56` | Fixed 48 dp button height with an unconstrained label Row — long submit labels clip at large font scale instead of wrapping to two lines. |

---

## Cross-cutting themes (worth fixing structurally, not one-by-one)

1. **Simulated features shipped as real.** Contact import, backup/restore, hold sale, image crop, language switch, product settings, dashboard search, printer "Ready". Each needs either an implementation or removal — right now they erode trust in every other button.
2. **Silent failure instead of error states.** `lastError` exists but no screen renders it; 4 screens swallow exceptions with `catch (_) {}`. A single `ErrorPanel(retry:)` widget wired into the 6 list screens would fix the class.
3. **Write paths that only touch memory.** `parties_screen` (2), `transaction_details` void, `today_bills` cancel, `more_screen` preferences — all update local state and skip the repository/API.
4. **Money is formatted ad hoc.** 141 hardcoded `Rs. ` literals, `.toInt()` truncation, mixed grouping/decimals, hardcoded 13% tax. One `MoneyText` widget + one formatter removes the whole family.
5. **Touch targets and labels below Material minimums.** 26/30/38/44 dp targets, no `Semantics`/`Tooltip` anywhere — this app is used one-handed on cheap phones in a shop.
6. **No i18n despite offering Nepali.** Either commit to `flutter_localizations` or drop the language row; the current state is a broken promise.
7. **Developer copy reaches shopkeepers.** "Docker container is running", `Print failed: ClientException…`, `$action tapped`. Everything user-facing should be written for the shopkeeper and the raw error logged.

## Suggested fix batches

| Batch | Findings | Why together |
|---|---|---|
| **A. Data honesty** | 01, 02, 04, 05, 10, 14, 43 | All "UI says saved, nothing saved" — highest trust damage |
| **B. Fake features** | 03, 08, 11, 15, 20 | Replace with real behavior or remove the entry points |
| **C. Money & receipts** | 06, 07, 23, 24 | One formatter + carry tax/charges through the sale |
| **D. Resilience & layout** | 13, 16, 17, 18, 27, 28, 42, 44 | Error state, discard guards, scrollable sheets, human copy |
| **E. Small-screen & a11y** | 19, 21, 22, 29, 30, plus the P3 table | Targets, labels, badge, overflow |

## Verification notes

- Every quoted line was re-read from the file after the audit; line numbers are current as of this report.
- `flutter analyze` → **No issues found** (13.9 s), so these are behavioral/visual defects, not static warnings.
- `flutter build web` was run to test one candidate finding (unconditional `dart:io` import in `app_lazy_image.dart`): **the web build succeeds**, so that finding was rejected and is not in this report.
- Claims that depend on runtime (e.g. exact overflow pixel thresholds) are marked with their trigger condition (`320 dp`, `~1.3× font`, short screens) rather than asserted unconditionally.

**Status: nothing fixed yet.** Say "fixed" and I'll start with batch A, then B, C, D, E — each batch as a separate, reviewable change set.
