## Database Views

### v_staff_daily_schedule
This view displays the daily schedule for staff members.
* The `appointment` table is the primary table.
* Joins include: `user` (staff name), `staff` (location), `company_location` (address), and `client`/`user` (client info).
* Uses two `LATERAL JOIN`s: one to aggregate all staff roles from `staff_type`, and one to aggregate all services linked to the appointment from `appointment_service`.
* Filtering: `status <> 'cancelled'` and `status <> 'completed'` are applied early to reduce processed records.
* The `LEAD()` function calculates the time gap between consecutive appointments without needing self-join operations.

### v_staff_open_slots
This view returns all available appointment slots.
* Aggregated sets (`staff_roles`, `staff_services`, `staff_rating`) are created first so aggregation happens only once.
* The main table is `staff_time_slot`.
* Filtering: `appointment_id IS NULL`, `slot_start >= NOW()`, and `slot_start < NOW() + INTERVAL '30 days'` are applied immediately.
* Performs JOINS with `staff`, `user`, `company_location`, and a `LEFT JOIN` with `blocked_time` where `b.block_id IS NULL` to exclude blocked slots.

### v_companies_by_category
Allows searching for companies by category and services.
* The `company_services` CTE aggregates all active services per company.
* The `s.is_active = TRUE` filter is applied before aggregation.
* Joins with `company_company_category`, `company_category`, and `company` ensure the main SELECT operates on a smaller dataset.

### v_staff_service_menu
Displays the services offered by each staff member.
* The `staff_service_ratings` CTE pre-calculates the average rating, number of reviews, and number of completions.
* Only appointments with `status = 'completed'` are analyzed, significantly reducing the data volume.

### v_monthly_revenue_by_company
Used for financial reporting.
* Uses only `invoice`, `appointment`, `company_location`, and `company` tables.
* Since `invoice` is smaller than `appointment_service`, calculation is highly efficient.
* All aggregates (`SUM`, `AVG`, `COUNT`) are computed in a single `GROUP BY` operation.

### v_future_appointments_client_o
Returns upcoming client appointments.
* Filters `appointment_date >= CURRENT_DATE` and `status <> 'cancelled'` are applied early to eliminate historical records.
* Uses `LATERAL JOIN` to aggregate services per appointment rather than a global `GROUP BY`.
* Optimized with index: `idx_appointment_client_future` on `appointment(client_id, appointment_date)`.

### v_client_dashboard
Designed for the client homepage.
* Uses two CTEs (`upcoming` and `recent_spend`) to pre-calculate upcoming appointments and spending from the last 30 days.
* The main SELECT joins these pre-aggregated results.
* Leverages the `idx_appointment_client_future` index for efficiency.

### v_staff_profile_m
Displays a full staff profile.
* Uses `mv_staff_avg_rating` (Materialized View) instead of recalculating ratings from `review`, saving execution time.
* Uses two `LATERAL JOIN`s for services and roles aggregation.
* Includes `WHERE u.is_active = TRUE` to ensure only active users are shown.

#### mv_staff_avg_rating
A Materialized View supporting `v_staff_profile_m`.
* Pre-calculates and physically stores average ratings in the database.
* Provides faster reads, fewer JOINs, and lower CPU usage.
* Refreshed via `REFRESH MATERIALIZED VIEW CONCURRENTLY`.
* Index `idx_appointment_staff_rating` on `appointment(staff_id)` allows for an *Index Only Scan*, reducing complexity from linear to logarithmic.

### v_invoice_detail_o
The most detailed financial view.
* The main table is `invoice`.
* Uses three `LATERAL JOIN`s for aggregating services, promo codes, and staff roles for each specific invoice.
* This is more efficient than global `GROUP BY` operations across the entire database.