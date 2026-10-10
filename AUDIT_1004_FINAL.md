# ARN Inventory • Revisi 1004 • Final Repair Audit

This build contains actual code/data/backend fixes, not checklist-only changes.

## Fixed in 1004
1. Existing remote accounts no longer receive an automatic new demo when an active license is missing. Admin license disable therefore cannot be bypassed by re-login.
2. Transaction RLS verifies both `account_id` and ownership of `part_id`; the stock guard trigger independently enforces part/account ownership.
3. Master seeding preserves existing user edits to master part identity/pricing/unit and only merges missing compatibility/reference data.
4. Transaction editing validates the new part separately when the part is changed.
5. Part lifecycle is complete: manual parts without history can be deleted with the existing 7-second confirmation; parts with history and master parts use deactivate/reactivate instead of destructive deletion.
6. Inactive categories remain selectable when editing a part that still belongs to them.
7. Part manager can search active and inactive parts so deactivated parts can be reactivated.
8. Login/Register license action now clearly states that activation occurs after successful account authentication; the actual activation remains backend-validated.
9. Opening stock baseline updated to the latest 16-row movement source dated 2026-09-14, including TG-UNK-01, TG-UNK-02 and BTN-003.
10. The 34-item inventory baseline is preloaded so recorded zero-stock lines are not lost.
11. Tempered-glass group names are restored to the clean group headings from the supplied master source.
12. Service-worker cache bumped to 1004 to invalidate older revisions.

## Static verification
- `node --check app.js`: passed.
- `master-data.json`: valid JSON.
- Master counts: 63 LCD groups / 488 LCD models / 209 battery codes / 18 TG groups / 34 inventory baseline rows / 16 opening movement rows.
- ZIP integrity and final file manifest are checked during packaging.

## Not claimed
A live production browser E2E against the user's deployed GitHub Pages and Supabase project is not claimed here because this build environment cannot reliably perform that full authenticated production flow.
