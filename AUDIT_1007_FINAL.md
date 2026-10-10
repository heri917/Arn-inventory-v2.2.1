# ARN Inventory V1007 Final Audit

Base: V1005 FINAL. V1005 features are preserved; V1007 adds only the requested admin/license and compatibility changes.

## Supabase prerequisites already applied
- customer_name added to arn_license_codes.
- admin helper and generator fixed.
- pgcrypto enabled.
- arn_admin_generate_license(text,text,integer) exists and is executable by authenticated.
- arn_part_compatibilities uses phone_model.
- source added for manual compatibility.
- unique normalized part/model index added.
- RLS INSERT/UPDATE hardened.
- arn_part_compatibility_all view added and readable by authenticated.
- arn_add_part_compatibility(uuid,text) exists and is executable by authenticated.
- Existing legacy license generator signature remains intact.

## PWA V1007
- Re-reads arn_profiles after account self-healing so current admin role is reflected.
- Admin license list loads customer_name.
- Admin license generator calls the V1007 RPC signature with p_customer_name and p_days.
- Blank customer name auto-generates sequential User N labels.
- Customer name persists in Supabase and is displayed in Admin Panel.
- Compatibility UI is available from every Part detail, including manual Parts.
- Compatibility UI reads combined master + manual compatibility view.
- Adding a model already present in master does not create another manual row.
- New compatibility calls arn_add_part_compatibility.
- Remote compatibility reads use phone_model, not the obsolete model column.
- Service worker cache advanced from 1005 to 1007 to avoid stale revisions.

## Static verification
- node --check app.js: PASS
- stale remote compatibility field `model`: not present in remote read/write paths
- stale `normalized_model` upsert path: removed
- V1005 legacy license function intentionally retained

## Live E2E
Not claimed here. Browser/device E2E requires deployment and a real authenticated session. The source has been statically validated only.
