CREATE OR REPLACE VIEW v_staff_daily_schedule AS

SELECT
    -- Staff
    a.staff_id,
    u.first_name || ' ' || u.last_name AS staff_name,

    sr.role_types,
    sr.role_types_arr,

    -- Location
    cl.city,
    cl.address,

    -- Appointment timing
    a.appointment_date,
    a.appointment_time AS start_time,
    a.end_time,
    asa.total_duration_minutes AS duration_minutes,

    -- Client
    uc.first_name || ' ' || uc.last_name AS client_name,
    c.phone AS client_phone,

    -- Services & pricing
    asa.service_names,
    asa.total_price AS booked_price,

    -- Appointment meta
    a.appointment_id,
    a.status,
    a.notes,

    -- Gap to next appointment
    EXTRACT(EPOCH FROM (
        LEAD(a.appointment_time)
        OVER (
            PARTITION BY a.staff_id, a.appointment_date
            ORDER BY a.appointment_time
        ) - a.end_time
    )) / 60 AS gap_after_minutes

FROM appointment a

-- Staff
JOIN "user" u ON u.user_id = a.staff_id
JOIN staff s ON s.staff_id = a.staff_id
JOIN company_location cl ON cl.location_id = s.location_id

-- Client
JOIN "user" uc ON uc.user_id = a.client_id
JOIN client c ON c.client_id = a.client_id

-- Roles (per staff, not global aggregation)
LEFT JOIN LATERAL (
    SELECT
        STRING_AGG(st.role_type::TEXT, ', ' ORDER BY st.role_type) AS role_types,
        ARRAY_AGG(st.role_type ORDER BY st.role_type) AS role_types_arr
    FROM staff_type st
    WHERE st.staff_id = a.staff_id
) sr ON TRUE

-- Services aggregation (per appointment, not global)
LEFT JOIN LATERAL (
    SELECT
        STRING_AGG(sv.service_name, ', ' ORDER BY sv.service_name) AS service_names,
        ARRAY_AGG(sv.service_id ORDER BY sv.service_id) AS service_ids,
        SUM(aas.price) AS total_price,
        SUM(aas.duration_minutes) AS total_duration_minutes
    FROM appointment_service aas
    JOIN service sv ON sv.service_id = aas.service_id
    WHERE aas.appointment_id = a.appointment_id
) asa ON TRUE

WHERE a.status <> 'cancelled' and a.status<> 'completed';

SELECT * FROM v_staff_daily_schedule WHERE staff_id = 35371;

CREATE OR REPLACE VIEW v_staff_open_slots AS

WITH staff_roles AS (SELECT staff_id,
                            STRING_AGG(role_type::TEXT, ', ' ORDER BY role_type) AS role_types
                     FROM staff_type
                     GROUP BY staff_id),

     staff_services AS (SELECT ss.staff_id,
                               STRING_AGG(sv.service_name, ', ' ORDER BY sv.service_name) AS service_names,
                               ARRAY_AGG(sv.service_id ORDER BY sv.service_id)            AS service_ids
                        FROM staff_service ss
                                 JOIN service sv ON sv.service_id = ss.service_id
                            AND sv.is_active = TRUE
                        GROUP BY ss.staff_id),

     staff_rating AS (SELECT a.staff_id,
                             ROUND(AVG(r.rating), 2) AS avg_rating,
                             COUNT(r.review_id)      AS review_count
                      FROM review r
                               JOIN appointment a ON a.appointment_id = r.appointment_id
                      GROUP BY a.staff_id)

SELECT ts.slot_id,
       ts.slot_start,
       ts.slot_end,
       ts.slot_start::date                      AS slot_date,
       ts.slot_start::time                      AS slot_time,
       TO_CHAR(ts.slot_start, 'Dy DD Mon YYYY') AS slot_label,

       s.staff_id,
       u.first_name || ' ' || u.last_name       AS staff_name,
       u.profile_image_url,
       sr.role_types,

       s.location_id,
       cl.address,
       cl.city,
       cl.phone                                 AS location_phone,
       cl.company_id,

       COALESCE(srt.avg_rating, 0)              AS staff_avg_rating,
       COALESCE(srt.review_count, 0)            AS staff_review_count,

       ss.service_ids,
       ss.service_names

FROM staff_time_slot ts
         JOIN staff s ON s.staff_id = ts.staff_id
         JOIN "user" u ON u.user_id = s.staff_id AND u.is_active = TRUE
         JOIN staff_roles sr ON sr.staff_id = s.staff_id
         JOIN company_location cl ON cl.location_id = s.location_id
         LEFT JOIN staff_services ss ON ss.staff_id = s.staff_id
         LEFT JOIN staff_rating srt ON srt.staff_id = s.staff_id
         LEFT JOIN blocked_time b ON b.staff_id = ts.staff_id
    AND ts.slot_start >= b.start_datetime
    AND ts.slot_start < b.end_datetime

WHERE ts.appointment_id IS NULL
  AND ts.slot_start >= NOW()
  AND ts.slot_start < NOW() + INTERVAL '30 days'
  AND b.block_id IS null;

SELECT * FROM v_staff_open_slots where staff_id = 26027;




CREATE OR REPLACE VIEW v_companies_by_category AS
WITH company_services AS (
    SELECT s.company_id,
           ccc.company_category_id,
           ARRAY_AGG(DISTINCT s.service_name ORDER BY s.service_name)        AS offered_service_names_arr,
           STRING_AGG(DISTINCT s.service_name, ', ' ORDER BY s.service_name) AS offered_service_names
    FROM service s
             JOIN company_company_category ccc ON ccc.company_id = s.company_id
    WHERE s.is_active = TRUE
    GROUP BY s.company_id, ccc.company_category_id
)
SELECT cc.company_category_id,
       cc.category_name,
       co.company_id,
       co.name        AS company_name,
       co.email,
       co.phone,
       co.description,
       co.is_active,
       cs.offered_service_names_arr,
       cs.offered_service_names
FROM company_company_category ccc
         JOIN company_category cc ON cc.company_category_id = ccc.company_category_id
         JOIN company co ON co.company_id = ccc.company_id
         LEFT JOIN company_services cs
                   ON cs.company_id = co.company_id
                   AND cs.company_category_id = ccc.company_category_id
WHERE co.is_active = TRUE;


SELECT *
from v_companies_by_category
WHERE offered_service_names ILIKE '%Haircut%';

SELECT *
from v_companies_by_category
WHERE category_name = 'Hair Salon';

SELECT *
from v_companies_by_category
WHERE category_name = 'Hair Removal'
  and offered_service_names ILIKE '%Wax%';


CREATE OR REPLACE VIEW v_staff_service_menu AS
WITH staff_service_ratings AS (SELECT a.staff_id,
                                      asv.service_id,
                                      ROUND(AVG(r.rating), 2)   AS avg_rating,
                                      COUNT(r.review_id)        AS review_count,
                                      COUNT(asv.appointment_id) AS times_performed
                               FROM appointment_service asv
                                        JOIN appointment a ON a.appointment_id = asv.appointment_id
                                        LEFT JOIN review r ON r.appointment_id = a.appointment_id
                               WHERE a.status = 'completed'
                               GROUP BY a.staff_id, asv.service_id)

SELECT ss.staff_id,
       sv.service_id,
       sv.service_name,
       sc.category_name,
       sv.duration_minutes,
       sv.price,
       ss.notes                         AS staff_service_notes,


       COALESCE(ssr.avg_rating, 0)      AS avg_rating,
       COALESCE(ssr.review_count, 0)    AS review_count,
       COALESCE(ssr.times_performed, 0) AS times_performed

FROM staff_service ss
         JOIN service sv ON sv.service_id = ss.service_id
         JOIN service_category sc ON sc.service_category_id = sv.service_category_id
         LEFT JOIN staff_service_ratings ssr
                   ON ssr.staff_id = ss.staff_id
                       AND ssr.service_id = ss.service_id
WHERE sv.is_active = true;


select *
from v_staff_service_menu
where staff_id = 23213
order by avg_rating desc, times_performed desc;



CREATE VIEW v_monthly_revenue_by_company AS
SELECT co.company_id,
       co.name                                  AS company_name,
       DATE_TRUNC('month', i.invoice_date)::date AS revenue_month,
       COUNT(*)                                  AS total_invoices,
       COUNT(DISTINCT i.client_id)               AS unique_clients,
       SUM(i.subtotal)                           AS gross_revenue,
       SUM(i.discount_total)                     AS total_discounts,
       SUM(i.tax)                                AS total_tax,
       SUM(i.total)                              AS net_revenue,
       ROUND(AVG(i.total), 2)                    AS avg_invoice_value,
       COUNT(CASE WHEN i.payment_method = 'card'           THEN 1 END) AS paid_by_card,
       COUNT(CASE WHEN i.payment_method = 'cash'           THEN 1 END) AS paid_by_cash,
       COUNT(CASE WHEN i.payment_method = 'loyalty_points' THEN 1 END) AS paid_by_points
FROM invoice i
         JOIN appointment a ON a.appointment_id = i.appointment_id
         JOIN company_location cl ON cl.location_id = a.location_id
         JOIN company co ON co.company_id = cl.company_id
GROUP BY co.company_id, co.name, DATE_TRUNC('month', i.invoice_date);



select *
from v_monthly_revenue_by_company
where company_id = 198;



CREATE OR REPLACE VIEW v_future_appointments_client_o AS
SELECT
    a.appointment_id,
    a.client_id,
    a.staff_id,
    a.location_id,
    a.appointment_date,
    a.appointment_time,
    a.end_time,
    a.status,
    a.notes,

    u.first_name  AS client_first_name,
    u.last_name   AS client_last_name,

    us.first_name AS staff_first_name,
    us.last_name  AS staff_last_name,

    asa.service_ids,
    asa.service_names,
    asa.total_price,
    asa.total_duration_minutes,

    cl.address,
    cl.city,
    cl.phone AS location_phone

FROM appointment a
    JOIN client c ON c.client_id = a.client_id
    JOIN "user" u ON u.user_id = a.client_id
    JOIN staff st ON st.staff_id = a.staff_id
    JOIN "user" us ON us.user_id = st.staff_id
    JOIN company_location cl ON cl.location_id = a.location_id

    LEFT JOIN LATERAL (
        SELECT
            STRING_AGG(sv.service_name, ', ' ORDER BY sv.service_name) AS service_names,
            ARRAY_AGG(sv.service_id ORDER BY sv.service_id)            AS service_ids,
            SUM(aas.price)                                             AS total_price,
            SUM(aas.duration_minutes)                                  AS total_duration_minutes
        FROM appointment_service aas
        JOIN service sv ON sv.service_id = aas.service_id
        WHERE aas.appointment_id = a.appointment_id
    ) asa ON TRUE

WHERE a.appointment_date >= NOW()::date
  AND a.status <> 'cancelled';

CREATE INDEX idx_appointment_client_future
    ON appointment (client_id, appointment_date)
    INCLUDE (staff_id, location_id, appointment_time, end_time, status, notes)
    WHERE status <> 'cancelled';

select *
from v_future_appointments_client_o
where client_id = 640295;


CREATE OR REPLACE VIEW v_client_dashboard AS
WITH upcoming AS (SELECT a.client_id,
                         COUNT(a.appointment_id) AS upcoming_appointments,
                         MIN(a.appointment_date) AS next_appointment_date
                  FROM appointment a
                  WHERE a.status NOT IN ('cancelled', 'completed')
                    AND a.appointment_date >= CURRENT_DATE
                  GROUP BY a.client_id),
     recent_spend AS (SELECT i.client_id,
                             SUM(i.total) AS last_30_days_spend
                      FROM invoice i
                      WHERE i.invoice_date >= CURRENT_DATE - INTERVAL '30 days'
                      GROUP BY i.client_id)
SELECT c.client_id,
       u.first_name || ' ' || u.last_name    AS client_name,
       c.loyalty_points,
       COALESCE(up.upcoming_appointments, 0) AS upcoming_appointments,
       up.next_appointment_date,
       COALESCE(rs.last_30_days_spend, 0)    AS last_30_days_spend,
       u.email,
       c.phone,
       c.date_of_birth
FROM client c
         JOIN "user" u ON u.user_id = c.client_id
         LEFT JOIN upcoming up ON up.client_id = c.client_id
         LEFT JOIN recent_spend rs ON rs.client_id = c.client_id;

select *
from v_client_dashboard
where client_id = 640295;



CREATE MATERIALIZED VIEW mv_staff_avg_rating AS
SELECT a.staff_id,
       ROUND(AVG(r.rating), 2) AS avg_rating,
       COUNT(r.review_id)      AS review_count
FROM appointment a
JOIN review r ON r.appointment_id = a.appointment_id
GROUP BY a.staff_id;

-- Index so the main view joins fast
CREATE UNIQUE INDEX ON mv_staff_avg_rating (staff_id);

CREATE OR REPLACE VIEW v_staff_profile_m AS
SELECT s.staff_id,
       u.first_name,
       u.last_name,
       u.first_name || ' ' || u.last_name AS full_name,
       u.email,
       u.profile_image_url,
       u.is_active,
       st.role_types,
       s.hourly_rate,
       s.location_id,
       cl.address,
       cl.city,
       cl.phone                           AS location_phone,
       cl.company_id,
       co.name                            AS company_name,
       COALESCE(mr.avg_rating, 0)         AS avg_rating,
       COALESCE(mr.review_count, 0)       AS review_count,
       ss.service_ids,
       ss.service_names
FROM staff s
         JOIN "user" u ON u.user_id = s.staff_id
         JOIN company_location cl ON cl.location_id = s.location_id
         JOIN company co ON co.company_id = cl.company_id

         -- Pre-computed ratings from materialized view
         LEFT JOIN mv_staff_avg_rating mr ON mr.staff_id = s.staff_id

         LEFT JOIN LATERAL (
            SELECT ARRAY_AGG(sv.service_id ORDER BY sv.service_id)            AS service_ids,
                   STRING_AGG(sv.service_name, ', ' ORDER BY sv.service_name) AS service_names
            FROM staff_service ss_inner
            JOIN service sv ON sv.service_id = ss_inner.service_id
            WHERE ss_inner.staff_id = s.staff_id AND sv.is_active = TRUE
         ) ss ON TRUE

         LEFT JOIN LATERAL (
            SELECT STRING_AGG(role_type::TEXT, ', ' ORDER BY role_type) AS role_types
            FROM staff_type
            WHERE staff_id = s.staff_id
         ) st ON TRUE

WHERE u.is_active = TRUE;

REFRESH MATERIALIZED VIEW CONCURRENTLY mv_staff_avg_rating;

CREATE INDEX idx_appointment_staff_rating
    ON appointment(staff_id) INCLUDE (appointment_id);

select *
from v_staff_profile_m
where company_id = 195
  and avg_rating > 4;

select *
from v_staff_profile_m
where staff_id = 365045;



CREATE OR REPLACE VIEW v_invoice_detail_o AS
SELECT i.invoice_id,
       i.invoice_date,
       i.payment_method,
       i.subtotal,
       i.discount_total,
       i.tax,
       i.total,

       ip.promo_codes_used,

       a.appointment_id,
       a.appointment_date,
       a.appointment_time,
       a.end_time,
       a.status                             AS appointment_status,

       c.client_id,
       uc.first_name || ' ' || uc.last_name AS client_name,
       uc.email                             AS client_email,
       c.phone                              AS client_phone,

       s.staff_id,
       us.first_name || ' ' || us.last_name AS staff_name,
       st.role_types,

       isv.service_names,
       isv.service_names_text,
       isv.services_total,

       cl.location_id,
       cl.address,
       cl.city,

       cl.company_id,
       co.name                              AS company_name
FROM invoice i
         JOIN appointment a ON a.appointment_id = i.appointment_id
         JOIN client c ON c.client_id = a.client_id
         JOIN "user" uc ON uc.user_id = c.client_id
         JOIN staff s ON s.staff_id = a.staff_id
         JOIN "user" us ON us.user_id = s.staff_id
         JOIN company_location cl ON cl.location_id = a.location_id
         JOIN company co ON co.company_id = cl.company_id


         LEFT JOIN LATERAL (
             SELECT ARRAY_AGG(sv.service_name ORDER BY sv.service_name)        AS service_names,
                    STRING_AGG(sv.service_name, ', ' ORDER BY sv.service_name) AS service_names_text,
                    SUM(asv_in.price)                                          AS services_total
             FROM appointment_service asv_in
                      JOIN service sv ON sv.service_id = asv_in.service_id
             WHERE asv_in.appointment_id = a.appointment_id
         ) isv ON TRUE


         LEFT JOIN LATERAL (
             SELECT STRING_AGG(p.code, ', ' ORDER BY p.code) AS promo_codes_used
             FROM invoice_promo ip_in
                      JOIN promo_code p ON p.promo_id = ip_in.promo_id
             WHERE ip_in.invoice_id = i.invoice_id
         ) ip ON TRUE


         LEFT JOIN LATERAL (
             SELECT STRING_AGG(role_type::TEXT, ', ' ORDER BY role_type) AS role_types
             FROM staff_type
             WHERE staff_id = s.staff_id
         ) st ON TRUE;

select *
from v_invoice_detail_o
where invoice_id = 1373796;
