INSERT INTO company_category (category_name)
VALUES ('Hair Salon'),
       ('Nail Salon'),
       ('Spa'),
       ('Beauty Salon'),
       ('Barbershop'),
       ('Massage Therapy'),
       ('Skin Care'),
       ('Eyebrow & Lash Studio'),
       ('Tanning Salon'),
       ('Waxing Studio'),
       ('Makeup Studio'),
       ('Hair Removal'),
       ('Wellness Center'),
       ('Med Spa');


-- ============================================================
--  11. SEED — COMPANY
-- ============================================================

WITH salon_names(n) AS (SELECT * FROM beauty_salon_names)
INSERT
INTO company (name, email, logo_url, description, created_at)
SELECT n,
       LOWER(REPLACE(n, ' ', '')) || '@mail.com',
       'https://img.com/' || ROW_NUMBER() OVER (),
       'Beauty salon services',
       NOW() - (random() * INTERVAL '25 years')
FROM salon_names;


-- ============================================================
--  12. SEED — COMPANY → CATEGORY
-- ============================================================

INSERT INTO company_company_category (company_id, company_category_id)
SELECT c.company_id, cat.company_category_id
FROM company c
         CROSS JOIN company_category cat
WHERE random() < 0.3
ON CONFLICT DO NOTHING;


-- ============================================================
--  13. SEED — COMPANY PHONE
-- ============================================================

UPDATE company
SET phone =
        CASE
            WHEN random() < 0.70 THEN '+389 7' || floor(random() * 3)::int::text
                                          || ' ' || floor(random() * 900 + 100)::int::text
                                          || ' ' || floor(random() * 900 + 100)::int::text
            WHEN random() < 0.33 THEN '+30 69' || floor(random() * 8 + 1)::int::text
                                          || ' ' || floor(random() * 900 + 100)::int::text
                                          || ' ' || floor(random() * 9000 + 1000)::int::text
            WHEN random() < 0.50 THEN '+359 8' || floor(random() * 9)::int::text
                                          || ' ' || floor(random() * 900 + 100)::int::text
                                          || ' ' || floor(random() * 9000 + 1000)::int::text
            ELSE '+381 6' || floor(random() * 9)::int::text
                     || ' ' || floor(random() * 900 + 100)::int::text
                     || ' ' || floor(random() * 9000 + 1000)::int::text
            END
where true;


-- ============================================================
--  14. SEED — COMPANY LOCATIONS
-- ============================================================

INSERT INTO company_location (company_id, address, city, phone)
SELECT c.company_id,
       (ARRAY ['Ilindenska','Partizanska','Jane Sandanski',
           'Bulevar Makedonija','Vodno','Goce Delchev',
           'Dimitar Vlahov'])[FLOOR(RANDOM() * 7 + 1)]
           || ' No. ' || FLOOR(RANDOM() * 200)::int,
       (ARRAY ['Skopje','Bitola','Ohrid','Tetovo',
           'Kumanovo','Prilep','Strumica'])[FLOOR(RANDOM() * 7 + 1)],
       '+3897' || FLOOR(1000000 + RANDOM() * 8999999)::text
FROM company c
         JOIN LATERAL generate_series(1, (1 + FLOOR(RANDOM() * 20))::int) gs ON TRUE;


-- ============================================================
--  15. SEED — BUSINESS HOURS
-- ============================================================

INSERT INTO business_hours (location_id, day_of_week, is_closed, open_time, close_time)
SELECT l.location_id,
       d.day_of_week,
       (d.day_of_week = 'sunday') AS is_closed,
       CASE
           WHEN d.day_of_week = 'sunday' THEN NULL
           WHEN d.day_of_week = 'saturday' THEN TIME '10:00' + (FLOOR(RANDOM() * 2) * INTERVAL '1 hour')
           ELSE TIME '08:00' + (FLOOR(RANDOM() * 5) * INTERVAL '1 hour')
           END                    AS open_time,
       CASE
           WHEN d.day_of_week = 'sunday' THEN NULL
           WHEN d.day_of_week = 'saturday' THEN TIME '10:00' + (FLOOR(RANDOM() * 2) * INTERVAL '1 hour')
               + (4 + FLOOR(RANDOM() * 2)) * INTERVAL '1 hour'
           ELSE TIME '08:00' + (FLOOR(RANDOM() * 5) * INTERVAL '1 hour')
               + (8 + FLOOR(RANDOM() * 3)) * INTERVAL '1 hour'
           END                    AS close_time
FROM company_location l
         CROSS JOIN (SELECT unnest(enum_range(NULL::day_of_week_enum)) AS day_of_week) d;


-- ============================================================
--  16. SEED — PROMO CODES
-- ============================================================

INSERT INTO promo_code (company_id, code, discount_type, discount_value, valid_from, valid_until)
SELECT c.company_id,
       UPPER(SUBSTRING(md5(RANDOM()::text), 1, 8)),
       (ARRAY ['percentage', 'fixed'])[FLOOR(RANDOM() * 2 + 1)]::discount_type_enum,
       CASE
           WHEN RANDOM() < 0.5 THEN ROUND((5 + RANDOM() * 45)::numeric, 2)
           ELSE ROUND((5 + RANDOM() * 50)::numeric, 2)
           END,
       CURRENT_DATE - (RANDOM() * INTERVAL '365 days'),
       CURRENT_DATE + (RANDOM() * INTERVAL '180 days')
FROM company c
         JOIN LATERAL generate_series(1, (1 + FLOOR(RANDOM() * 5))::int) gs ON TRUE;


-- ============================================================
--  17. SEED — USER TABLE
-- ============================================================

INSERT INTO "user" (first_name, last_name, email, password_hash, role, is_active, created_at)
SELECT fn,
       ln,
       lower(fn) || '.' || lower(ln) || row_number() OVER () || '@example.com',
       md5(random()::text),
       CASE
           WHEN rnd < 0.003 THEN 'admin'
           WHEN rnd < 0.053 THEN 'staff'
           WHEN rnd < 0.083 THEN 'owner'
           ELSE 'client'
           END::user_role_enum,
       random() < 0.85,
       NOW() - (pow(random(), 2) * INTERVAL '5 years')
FROM (SELECT fn,
             ln,
             random() AS rnd
      FROM first_names_200_mf  AS f(fn)
               CROSS JOIN last_names_40 AS l(ln)
               CROSS JOIN generate_series(1, 1000)
      ORDER BY random()
      LIMIT 1000000) base;


-- ============================================================
--  18. SEED — CLIENT TABLE
-- ============================================================

INSERT INTO client (client_id, loyalty_points, date_of_birth, phone, notes)
SELECT user_id,
       floor(random() * 5000)::int,
       CURRENT_DATE - (floor(random() * 18628 + 6570)::int) * INTERVAL '1 day',
       CASE
           WHEN random() < 0.70 THEN '+389 7' || floor(random() * 3)::int::text
                                         || ' ' || floor(random() * 900 + 100)::int::text
                                         || ' ' || floor(random() * 900 + 100)::int::text
           WHEN random() < 0.33 THEN '+30 69' || floor(random() * 8 + 1)::int::text
                                         || ' ' || floor(random() * 900 + 100)::int::text
                                         || ' ' || floor(random() * 9000 + 1000)::int::text
           WHEN random() < 0.50 THEN '+359 8' || floor(random() * 9)::int::text
                                         || ' ' || floor(random() * 900 + 100)::int::text
                                         || ' ' || floor(random() * 9000 + 1000)::int::text
           ELSE '+381 6' || floor(random() * 9)::int::text
                    || ' ' || floor(random() * 900 + 100)::int::text
                    || ' ' || floor(random() * 9000 + 1000)::int::text
           END,
       NULL
FROM "user"
WHERE role = 'client';


-- ============================================================
--  19. SEED — OWNER TABLE
-- ============================================================

WITH company_slots AS (SELECT company_id,
                              generate_series(1, (1 + FLOOR(RANDOM() * 3))::int) AS slot
                       FROM company),
     numbered_slots AS (SELECT company_id,
                               ROW_NUMBER() OVER () AS rn
                        FROM company_slots),
     shuffled_owners AS (SELECT user_id,
                                ROW_NUMBER() OVER (ORDER BY RANDOM()) AS rn
                         FROM "user"
                         WHERE role = 'owner'
                         LIMIT (SELECT COUNT(*) FROM numbered_slots))
INSERT
INTO owner (owner_id, company_id)
SELECT o.user_id, s.company_id
FROM shuffled_owners o
         JOIN numbered_slots s ON o.rn = s.rn;

UPDATE owner
SET owner_since = NOW() - random() * INTERVAL '10 years'
where true;


-- ============================================================
--  20. SEED — STAFF TABLE
-- ============================================================

INSERT INTO staff (staff_id, location_id, date_hired, hourly_rate)
SELECT u.user_id,
       cl.location_id,
       CURRENT_DATE - (RANDOM() * INTERVAL '5 years'),
       ROUND((10 + RANDOM() * 40)::numeric, 2)
FROM (SELECT user_id,
             ROW_NUMBER() OVER (ORDER BY user_id) AS rn
      FROM "user"
      WHERE role = 'staff') u
         JOIN (SELECT location_id,
                      ROW_NUMBER() OVER (ORDER BY location_id) AS rn,
                      COUNT(*) OVER ()                         AS total
               FROM company_location) cl ON ((u.rn - 1) % cl.total) = (cl.rn - 1);



-- ============================================================
--  21. SEED — STAFF TYPE
-- ============================================================

INSERT INTO staff_type (staff_id, role_type, specialty, certification, years_experience, extra_info)
SELECT s.staff_id,
       (ARRAY ['hairdresser','nail_tech','esthetician',
           'makeup_artist','receptionist'])[FLOOR(RANDOM() * 5 + 1)]::staff_role_type_enum,
       'General Specialty',
       'Certified Professional',
       FLOOR(RANDOM() * 15)::int,
       'Staff member'
FROM staff s
ON CONFLICT (staff_id, role_type) DO NOTHING;


-- ============================================================
--  22. SEED — SERVICE CATEGORIES
-- ============================================================

INSERT INTO service_category (category_name, description)
VALUES ('Haircuts', 'Basic and premium haircut services for men and women.'),
       ('Hair Coloring', 'Highlights, full color, balayage, root touch-ups, and color correction.'),
       ('Extensions & Weaves', 'Hair extensions, tape-ins, clip-ins, and weaves for added length and volume.'),
       ('Styling & Blowouts', 'Blowouts, updos, curls, and everyday styling for events and special occasions.'),
       ('Nail Manicure', 'Basic nail care, shaping, cuticle treatment, and polish application.'),
       ('Nail Pedicure', 'Foot soak, exfoliation, callus removal, and nail polish application.'),
       ('Nail Art & Design', 'Decorative nail art, patterns, and custom designs.'),
       ('Acrylic & Gel Nails', 'Acrylic, gel, and hard-gel overlay services for long-lasting nails.'),
       ('Natural Nail Care', 'Gentle care focused on strengthening and maintaining healthy natural nails.'),
       ('Facials', 'Deep cleansing, exfoliation, masks, and moisturizing treatments for the face.'),
       ('Body Treatments', 'Body scrubs, wraps, and hydrating treatments for the whole body.'),
       ('Massages', 'Relaxing and therapeutic massages including neck, shoulder, back, and full-body.'),
       ('Manicure & Pedicure', 'Combined hand and foot nail services for relaxation and grooming.'),
       ('Waxing', 'Hair removal using wax for brows, legs, arms, bikini, and other body areas.'),
       ('Laser Hair Removal', 'Laser-based permanent or semi-permanent hair reduction.'),
       ('Eyebrow Shaping', 'Brow waxing, threading, or trimming for well-defined shape.'),
       ('Eyebrow Tinting', 'Enhancing brow color for a fuller, more defined look.'),
       ('Lash Extensions', 'Individual or volume lash extensions for longer, fuller lashes.'),
       ('Lash Lift & Tint', 'Lifting and tinting natural lashes for a wide-eyed look.'),
       ('Spray Tanning', 'Professional spray tanning for an even, sun-kissed glow.'),
       ('Bronzing & Contouring', 'Makeup contouring for facial definition and sculpting.'),
       ('Makeup Application', 'Day, evening, or special-event makeup application.'),
       ('Bridal Makeup', 'Full bridal makeup trial and wedding-day application.'),
       ('Skincare Consultation', 'Personalized skin analysis and tailored treatment plans.'),
       ('Chemical Peels', 'Exfoliating treatments to improve texture, tone, and clarity of the skin.'),
       ('Microneedling', 'Collagen-stimulating procedure to reduce fine lines, scars, and pores.'),
       ('Facial Hair Removal', 'Precision removal of facial hair using wax, threading, or threading-based methods.'),
       ('Body Hair Removal', 'Waxing and laser-assisted removal for larger body areas.'),
       ('Manicure & Pedicure Men', 'Manicure and pedicure services tailored for men.'),
       ('Men Haircuts', 'Haircut and styling services designed specifically for men.'),
       ('Men Beard Grooming', 'Beard trimming, shaping, oiling, and styling.'),
       ('Men Skincare', 'Facial and body skincare routines for men.'),
       ('Detox & Wellness Massage', 'Massage focused on detoxification and overall wellness.'),
       ('Aromatherapy Massage', 'Massage using essential oils to enhance relaxation and mood.'),
       ('Hot Stone Massage', 'Massage using heated stones to relieve muscle tension.'),
       ('Couples Massage', 'Simultaneous massage for two people in a relaxing environment.'),
       ('Prenatal Massage', 'Gentle massage tailored for pregnant women.'),
       ('Deep Tissue Massage', 'Intensive massage targeting deeper muscle layers and tension.'),
       ('Sports Massage', 'Massage focused on athletes and performance recovery.'),
       ('Body Polish & Exfoliation', 'Full-body exfoliation to remove dead skin and leave skin smooth.'),
       ('Hydration & Nourishing Treatments', 'Intensive moisturizing masks and treatments for dry or tired skin.'),
       ('Acne & Problem Skin Care', 'Targeted treatments for acne, breakouts, and oily or sensitive skin.'),
       ('Anti-Aging Treatments', 'Procedures and masks aimed at reducing signs of aging and wrinkles.'),
       ('Brightening & Even Skin Tone', 'Treatments designed to lighten dark spots and even out skin tone.'),
       ('LED Light Therapy', 'Non-invasive light treatments to support skin healing and rejuvenation.'),
       ('Microdermabrasion', 'Mechanical exfoliation to improve skin texture and brightness.'),
       ('Facial Cleansing', 'Deep cleansing and pore extraction for clearer skin.'),
       ('Facial Hydration', 'Intensive hydration masks and serums for dry or dehydrated skin.'),
       ('Body Sculpting & Wraps', 'Wraps and treatments aimed at temporary contouring and detox.'),
       ('Threading & Eyebrow Services', 'Precision threading for brows and facial hair lineups.'),
       ('Lash & Brow Tinting Combo', 'Combined tinting service for both lashes and brows.'),
       ('Express Manicure', 'Quick manicure focusing on basic shaping and polish.'),
       ('Express Pedicure', 'Fast pedicure service for basic nail care and polish.'),
       ('Express Facial', 'Short facial treatment for busy clients.'),
       ('Express Waxing', 'Quick waxing for small areas like brows or upper lip.'),
       ('On-Site Services', 'Mobile or on-site beauty services for events and home visits.'),
       ('Glow-Up Packages', 'Curated packages designed to enhance overall appearance and confidence.'),
       ('Consultation Only', 'Initial consultation without treatment for plan and pricing discussion.'),
       ('Hair Treatment', 'Keratin treatments, deep conditioning, scalp therapy, and repair treatments.'),
       ('Botox', 'Botulinum toxin injections to reduce wrinkles and fine lines.'),
       ('Fillers', 'Dermal filler injections for volume, contouring, and wrinkle correction.'),
       ('Body Contouring', 'Non-surgical body shaping treatments to reduce fat and tighten skin.');

WITH category_mapping(comp_cat, svc_cat) AS (VALUES ('Hair Salon', 'Haircuts'),
                                                    ('Hair Salon', 'Hair Coloring'),
                                                    ('Hair Salon', 'Extensions & Weaves'),
                                                    ('Hair Salon', 'Styling & Blowouts'),
                                                    ('Hair Salon', 'Hair Treatment'),
                                                    ('Nail Salon', 'Nail Manicure'),
                                                    ('Nail Salon', 'Nail Pedicure'),
                                                    ('Nail Salon', 'Nail Art & Design'),
                                                    ('Nail Salon', 'Acrylic & Gel Nails'),
                                                    ('Nail Salon', 'Express Manicure'),
                                                    ('Barbershop', 'Men Haircuts'),
                                                    ('Barbershop', 'Men Beard Grooming'),
                                                    ('Barbershop', 'Men Skincare'),
                                                    ('Spa', 'Massages'),
                                                    ('Spa', 'Body Treatments'),
                                                    ('Spa', 'Hot Stone Massage'),
                                                    ('Spa', 'Facial Hydration'),
                                                    ('Skin Care', 'Facials'),
                                                    ('Skin Care', 'Chemical Peels'),
                                                    ('Skin Care', 'Microneedling'),
                                                    ('Skin Care', 'Skincare Consultation'),
                                                    ('Waxing Studio', 'Waxing'),
                                                    ('Waxing Studio', 'Facial Hair Removal'),
                                                    ('Waxing Studio', 'Express Waxing'),
                                                    ('Eyebrow & Lash Studio', 'Eyebrow Shaping'),
                                                    ('Eyebrow & Lash Studio', 'Eyebrow Tinting'),
                                                    ('Eyebrow & Lash Studio', 'Lash Extensions'),
                                                    ('Med Spa', 'Botox'),
                                                    ('Med Spa', 'Fillers'),
                                                    ('Med Spa', 'Body Contouring'),
                                                    ('Med Spa', 'Chemical Peels'),
                                                    ('Massage Therapy', 'Massages'),
                                                    ('Massage Therapy', 'Deep Tissue Massage'),
                                                    ('Massage Therapy', 'Sports Massage')),

-- 2. Дефинираме конкретни услуги за секоја категорија на услуга
     service_blueprints(svc_cat_name, svc_name, duration, base_price) AS (VALUES ('Haircuts', 'Basic Haircut', 30,
                                                                                  35.00),
                                                                                 ('Hair Coloring', 'Full Hair Color',
                                                                                  90,
                                                                                  120.00),
                                                                                 ('Styling & Blowouts',
                                                                                  'Blowout Styling', 45,
                                                                                  55.00),
                                                                                 ('Men Haircuts', 'Men’s Fade & Style',
                                                                                  45,
                                                                                  40.00),
                                                                                 ('Men Beard Grooming',
                                                                                  'Full Beard Grooming',
                                                                                  30, 30.00),
                                                                                 ('Hair Treatment',
                                                                                  'Deep Conditioning Mask',
                                                                                  45, 60.00),


                                                                                 ('Nail Manicure', 'Classic Manicure',
                                                                                  30,
                                                                                  25.00),
                                                                                 ('Nail Pedicure', 'Spa Pedicure', 45,
                                                                                  40.00),
                                                                                 ('Nail Art & Design',
                                                                                  'Custom Nail Art (Full Set)', 60,
                                                                                  50.00),
                                                                                 ('Acrylic & Gel Nails',
                                                                                  'Gel Extensions', 90,
                                                                                  85.00),


                                                                                 ('Facials', 'Signature Facial', 60,
                                                                                  85.00),
                                                                                 ('Body Treatments',
                                                                                  'Sea Salt Body Scrub', 60,
                                                                                  95.00),
                                                                                 ('Chemical Peels', 'Glycolic Peel', 45,
                                                                                  85.00),
                                                                                 ('Microneedling',
                                                                                  'Microneedling Session',
                                                                                  120, 250.00),
                                                                                 ('Skincare Consultation',
                                                                                  'Skin Analysis & Plan', 30, 45.00),


                                                                                 ('Waxing', 'Full Body Wax', 120,
                                                                                  140.00),
                                                                                 ('Laser Hair Removal',
                                                                                  'Laser Hair Removal - Face', 30,
                                                                                  150.00),
                                                                                 ('Eyebrow Shaping',
                                                                                  'Signature Brow Shaping',
                                                                                  30, 25.00),


                                                                                 ('Lash Extensions',
                                                                                  'Lash Extensions - Classic', 90,
                                                                                  120.00),
                                                                                 ('Lash Lift & Tint',
                                                                                  'Lash Lift & Tint Combo',
                                                                                  60, 110.00),
                                                                                 ('Spray Tanning',
                                                                                  'Spray Tan - Full Body', 30,
                                                                                  50.00),


                                                                                 ('Makeup Application',
                                                                                  'Full Face Glam', 60,
                                                                                  75.00),
                                                                                 ('Bridal Makeup',
                                                                                  'Bridal Trial & Day-of',
                                                                                  120, 250.00),
                                                                                 ('Bronzing & Contouring',
                                                                                  'Express Sculpt & Glow', 30, 40.00),


                                                                                 ('Massages', 'Swedish Massage', 60,
                                                                                  80.00),
                                                                                 ('Deep Tissue Massage',
                                                                                  'Deep Tissue Relief',
                                                                                  60, 110.00),
                                                                                 ('Hot Stone Massage',
                                                                                  'Hot Stone Therapy', 90,
                                                                                  130.00),
                                                                                 ('Aromatherapy Massage',
                                                                                  'Essential Oil Relaxer', 60, 95.00),


                                                                                 ('Botox', 'Botox Treatment (per area)',
                                                                                  30,
                                                                                  200.00),
                                                                                 ('Fillers', 'Dermal Filler Session',
                                                                                  45,
                                                                                  500.00),


                                                                                 ('Consultation Only',
                                                                                  'Professional Consultation', 15,
                                                                                  0.00))

INSERT
INTO service (company_id, service_category_id, service_name, duration_minutes, price, is_active)
SELECT ccc.company_id,
       sc.service_category_id,
       sb.svc_name,
       sb.duration,
       sb.base_price,
       TRUE
FROM company_company_category ccc
         JOIN company_category cc ON ccc.company_category_id = cc.company_category_id
         JOIN category_mapping cm ON cc.category_name = cm.comp_cat
         JOIN service_category sc ON sc.category_name = cm.svc_cat
         JOIN service_blueprints sb ON sb.svc_cat_name = sc.category_name
ON CONFLICT DO NOTHING;


-- ============================================================
--  24. SEED — STAFF SERVICE
-- ============================================================

INSERT INTO staff_service (staff_id, service_id)
SELECT DISTINCT ON (s.staff_id, sv.service_id) s.staff_id,
                                               sv.service_id
FROM staff s
         JOIN staff_type st ON st.staff_id = s.staff_id
         JOIN company_location cl ON cl.location_id = s.location_id
         JOIN service sv ON sv.company_id = cl.company_id AND sv.is_active = TRUE
         JOIN service_category sc ON sc.service_category_id = sv.service_category_id
WHERE (
    (st.role_type = 'hairdresser' AND sc.category_name IN (
                                                           'Haircuts', 'Hair Coloring', 'Extensions & Weaves',
                                                           'Styling & Blowouts', 'Men Haircuts', 'Men Beard Grooming',
                                                           'Hair Treatment'))
        OR (st.role_type = 'nail_tech' AND sc.category_name IN (
                                                                'Nail Manicure', 'Nail Pedicure', 'Nail Art & Design',
                                                                'Acrylic & Gel Nails', 'Natural Nail Care',
                                                                'Manicure & Pedicure',
                                                                'Express Manicure', 'Express Pedicure'))
        OR (st.role_type = 'esthetician' AND sc.category_name IN (
                                                                  'Facials', 'Body Treatments', 'Waxing',
                                                                  'Laser Hair Removal',
                                                                  'Chemical Peels', 'Microneedling', 'Eyebrow Shaping',
                                                                  'Eyebrow Tinting',
                                                                  'Lash Extensions', 'Lash Lift & Tint',
                                                                  'Spray Tanning', 'Massages',
                                                                  'Deep Tissue Massage', 'Sports Massage',
                                                                  'Hot Stone Massage',
                                                                  'Couples Massage', 'Aromatherapy Massage',
                                                                  'Prenatal Massage',
                                                                  'Detox & Wellness Massage',
                                                                  'Acne & Problem Skin Care',
                                                                  'Anti-Aging Treatments', 'Facial Hair Removal',
                                                                  'Body Hair Removal',
                                                                  'Skincare Consultation', 'Skin Care',
                                                                  'LED Light Therapy', 'Microdermabrasion',
                                                                  'Body Contouring',
                                                                  'Botox', 'Fillers'))
        OR (st.role_type = 'makeup_artist' AND sc.category_name IN (
                                                                    'Makeup Application', 'Bridal Makeup',
                                                                    'Bronzing & Contouring'))
        OR (st.role_type = 'receptionist' AND sc.category_name IN (
                                                                   'Skincare Consultation', 'Consultation Only'))
    )
  AND (SELECT COUNT(*) FROM staff_service ss WHERE ss.staff_id = s.staff_id) < 3
ON CONFLICT DO NOTHING;


-- ============================================================
--  25. SEED — STAFF AVAILABILITY
-- ============================================================

WITH location_hours AS (SELECT bh.location_id,
                               bh.day_of_week,
                               bh.open_time,
                               bh.close_time,
                               EXTRACT(EPOCH FROM (bh.close_time - bh.open_time)) / 60 AS available_minutes
                        FROM business_hours bh
                        WHERE bh.is_closed = FALSE
                          AND bh.day_of_week::text <> 'sunday'),
     staff_days AS (SELECT s.staff_id,
                           lh.day_of_week,
                           lh.open_time,
                           lh.available_minutes
                    FROM staff s
                             JOIN location_hours lh ON lh.location_id = s.location_id),
     staff_shifts AS (SELECT staff_id,
                             day_of_week,
                             open_time,
                             available_minutes,
                             LEAST(
                                     (ARRAY [240, 360, 480])[FLOOR(RANDOM() * 3 + 1)::int],
                                     available_minutes::int
                             ) AS shift_minutes
                      FROM staff_days),
     staff_timed AS (SELECT staff_id,
                            day_of_week,
                            open_time,
                            available_minutes,
                            shift_minutes,
                            SQRT(-2.0 * LN(NULLIF(RANDOM(), 0))) * COS(2 * PI() * RANDOM()) AS z
                     FROM staff_shifts),
     staff_timed_clamped AS (SELECT staff_id,
                                    day_of_week,
                                    shift_minutes,
                                    (open_time + (
                                        GREATEST(0, LEAST(
                                                available_minutes - shift_minutes,
                                                ROUND(
                                                        ((available_minutes - shift_minutes) / 2.0)
                                                            + z * ((available_minutes - shift_minutes) / 6.0)
                                                )
                                                    )) || ' minutes')::interval)::time AS start_time
                             FROM staff_timed)
INSERT
INTO staff_availability (staff_id, day_of_week, start_time, end_time)
SELECT staff_id,
       day_of_week,
       start_time,
       (start_time + (shift_minutes || ' minutes')::interval)::time AS end_time
FROM staff_timed_clamped
ON CONFLICT (staff_id, day_of_week) DO NOTHING;



-- ============================================================
--  26. SEED — BLOCKED TIME
-- ============================================================

WITH block_series AS (SELECT s.staff_id,
                             gs.block_num,
                             random() < 0.60                                 AS is_single_day,
                             (NOW() - (random() * INTERVAL '2 years'))::date AS block_date,
                             random()                                        AS reason_rnd
                      FROM staff s
                               CROSS JOIN generate_series(1, (2 + FLOOR(RANDOM() * 4))::int) AS gs(block_num)),
     blocks_computed AS (SELECT staff_id,
                                (block_date::timestamp + TIME '09:00')::timestamptz AS start_datetime,
                                CASE
                                    WHEN is_single_day
                                        THEN (block_date::timestamp + TIME '17:00')::timestamptz
                                    ELSE (block_date::timestamp
                                        + ((3 + FLOOR(RANDOM() * 5)) || ' days')::interval
                                        + TIME '17:00')::timestamptz
                                    END                                             AS end_datetime,
                                CASE
                                    WHEN reason_rnd < 0.20 THEN 'Sick day'
                                    WHEN reason_rnd < 0.40 THEN 'Personal leave'
                                    WHEN reason_rnd < 0.55 THEN 'Vacation'
                                    WHEN reason_rnd < 0.70 THEN 'Medical appointment'
                                    WHEN reason_rnd < 0.80 THEN 'Family emergency'
                                    WHEN reason_rnd < 0.90 THEN 'Training / workshop'
                                    END                                             AS reason
                         FROM block_series)
INSERT
INTO blocked_time (staff_id, start_datetime, end_datetime, reason)
SELECT staff_id, start_datetime, end_datetime, reason
FROM blocks_computed
WHERE end_datetime > start_datetime;


-- ============================================================
--  27. SEED — APPOINTMENTS + APPOINTMENT_SERVICE
-- ============================================================

-- COMPLETED ROWS
CREATE TEMP TABLE tmp_clients AS
SELECT client_id,
       ROW_NUMBER() OVER (ORDER BY random()) AS rn
FROM client;

CREATE TEMP TABLE tmp_staff_service AS
SELECT ss.staff_id,
       ss.service_id,
       sv.duration_minutes,
       sv.price,
       s.location_id,
       ROW_NUMBER() OVER (ORDER BY random()) AS rn
FROM staff_service ss
         JOIN service sv ON sv.service_id = ss.service_id
         JOIN staff s ON s.staff_id = ss.staff_id;

INSERT INTO appointment (client_id, staff_id, location_id,
                         appointment_date, appointment_time, end_time,
                         status, booked_at, cancelled_at, cancellation_reason)
SELECT DISTINCT ON (gen.staff_id, gen.appt_date, gen.start_time) t.client_id,
                                                                 gen.staff_id,
                                                                 gen.location_id,
                                                                 gen.appt_date,
                                                                 gen.start_time,
                                                                 (gen.start_time + (gen.duration_minutes || ' minutes')::interval)::time,
                                                                 gen.status_val,
                                                                 (gen.appt_date::timestamp - (random() * INTERVAL '30 days'))::timestamptz,
                                                                 CASE
                                                                     WHEN gen.status_val = 'cancelled'
                                                                         THEN (gen.appt_date::timestamp - (random() * INTERVAL '5 days'))::timestamptz
                                                                     END,
                                                                 CASE
                                                                     WHEN gen.status_val = 'cancelled'
                                                                         THEN (ARRAY ['Client no-show','Staff unavailable','Personal reasons',
                                                                         'Rescheduled','Weather conditions'])[FLOOR(random() * 5 + 1)::int]
                                                                     END
FROM (SELECT ss.staff_id,
             ss.location_id,
             ss.duration_minutes,
             (CURRENT_DATE - (random() * 1825)::int)                                  AS appt_date,
             (TIME '08:00' + (FLOOR(random() * 40) * 15) * INTERVAL '1 minute')::time AS start_time,
             CASE
                 WHEN random() < 0.60 THEN 'completed'
                 WHEN random() < 0.75 THEN 'confirmed'
                 WHEN random() < 0.90 THEN 'cancelled'
                 ELSE 'pending'
                 END::appointment_status_enum                                         AS status_val,
             ROW_NUMBER() OVER ()                                                     AS rn
      FROM tmp_staff_service ss
               CROSS JOIN generate_series(1, 10)
      ORDER BY random()
      LIMIT 500000) gen
         JOIN tmp_clients t ON (gen.rn % (SELECT COUNT(*) FROM tmp_clients)) = (t.rn - 1)
ON CONFLICT (staff_id, appointment_date, appointment_time) DO NOTHING;

DROP TABLE tmp_clients;
DROP TABLE tmp_staff_service;

select count(*) from appointment a ; 
---- PENDING ROWS

CREATE TEMP TABLE tmp_clients_p AS
SELECT client_id,
       ROW_NUMBER() OVER (ORDER BY random()) AS rn
FROM client;

CREATE TEMP TABLE tmp_staff_service_p AS
SELECT ss.staff_id,
       ss.service_id,
       sv.duration_minutes,
       sv.price,
       s.location_id,
       ROW_NUMBER() OVER (ORDER BY random()) AS rn
FROM staff_service ss
         JOIN service sv ON sv.service_id = ss.service_id
         JOIN staff s ON s.staff_id = ss.staff_id;

INSERT INTO appointment (client_id, staff_id, location_id,
                         appointment_date, appointment_time, end_time,
                         status, booked_at, cancelled_at, cancellation_reason)
SELECT DISTINCT ON (gen.staff_id, gen.appt_date, gen.start_time) t.client_id,
                                                                 gen.staff_id,
                                                                 gen.location_id,
                                                                 gen.appt_date,
                                                                 gen.start_time,
                                                                 (gen.start_time + (gen.duration_minutes || ' minutes')::interval)::time,
                                                                 'pending'::appointment_status_enum,
                                                                 (NOW() - (random() * INTERVAL '14 days'))::timestamptz,
                                                                 NULL,
                                                                 NULL
FROM (SELECT tss.staff_id,
             tss.location_id,
             tss.duration_minutes,
             (CURRENT_DATE + (14 + (random() * 106)::int))                            AS appt_date,
             (TIME '08:00' + (FLOOR(random() * 40) * 15) * INTERVAL '1 minute')::time AS start_time,
             ROW_NUMBER() OVER ()                                                     AS rn
      FROM tmp_staff_service_p tss
               CROSS JOIN generate_series(1, 10)
      ORDER BY random()
      LIMIT 500000) gen
         JOIN tmp_clients_p t ON (gen.rn % (SELECT COUNT(*) FROM tmp_clients_p)) = (t.rn - 1)
ON CONFLICT (staff_id, appointment_date, appointment_time) DO NOTHING;

DROP TABLE tmp_clients_p;
DROP TABLE tmp_staff_service_p;


---CANCELLED ROWS

CREATE TEMP TABLE tmp_clients_c AS
SELECT client_id,
       ROW_NUMBER() OVER (ORDER BY random()) AS rn
FROM client;

CREATE TEMP TABLE tmp_staff_service_c AS
SELECT ss.staff_id,
       ss.service_id,
       sv.duration_minutes,
       sv.price,
       s.location_id,
       ROW_NUMBER() OVER (ORDER BY random()) AS rn
FROM staff_service ss
         JOIN service sv ON sv.service_id = ss.service_id
         JOIN staff s ON s.staff_id = ss.staff_id;

INSERT INTO appointment (client_id, staff_id, location_id,
                         appointment_date, appointment_time, end_time,
                         status, booked_at, cancelled_at, cancellation_reason)
SELECT DISTINCT ON (gen.staff_id, gen.appt_date, gen.start_time) t.client_id,
                                                                 gen.staff_id,
                                                                 gen.location_id,
                                                                 gen.appt_date,
                                                                 gen.start_time,
                                                                 (gen.start_time + (gen.duration_minutes || ' minutes')::interval)::time,
                                                                 'cancelled'::appointment_status_enum,
                                                                 -- booked_at before the appointment date
                                                                 (gen.appt_date::timestamp - (random() * INTERVAL '30 days'))::timestamptz,
                                                                 -- canceled_at: between booked_at and the appointment date (1–5 days before appt)
                                                                 (gen.appt_date::timestamp - (random() * INTERVAL '5 days'))::timestamptz,
                                                                 (ARRAY ['Client no-show','Staff unavailable','Personal reasons',
                                                                     'Rescheduled','Weather conditions'])[FLOOR(random() * 5 + 1)::int]
FROM (SELECT tssc.staff_id,
             tssc.location_id,
             tssc.duration_minutes,
             -- any point in the past 5 years
             (CURRENT_DATE - (random() * 1825)::int)                                  AS appt_date,
             (TIME '08:00' + (FLOOR(random() * 40) * 15) * INTERVAL '1 minute')::time AS start_time,
             ROW_NUMBER() OVER ()                                                     AS rn
      FROM tmp_staff_service_c tssc
               CROSS JOIN generate_series(1, 10)
      ORDER BY random()
      LIMIT 100000) gen
         JOIN tmp_clients_c t ON (gen.rn % (SELECT COUNT(*) FROM tmp_clients_c)) = (t.rn - 1)
ON CONFLICT (staff_id, appointment_date, appointment_time) DO NOTHING;

DROP TABLE tmp_clients_c;

DROP TABLE tmp_staff_service_c;


-- APPOINTMENT SERVICE
INSERT INTO appointment_service (appointment_id, service_id, duration_minutes, price)
SELECT appointment_id, service_id, duration_minutes, price
FROM (SELECT a.appointment_id,
             s.service_id,
             s.duration_minutes,
             s.price,
             ROW_NUMBER() OVER (
                 PARTITION BY a.appointment_id
                 ORDER BY random()
                 ) AS rn
      FROM appointment a
               JOIN staff_service ss ON ss.staff_id = a.staff_id
               JOIN service s ON s.service_id = ss.service_id
      WHERE random() < 0.6) sub
WHERE rn <= 3
ON CONFLICT DO NOTHING;



-- UPDATE na end_time spored sum od services vo Appointment

UPDATE appointment a
SET end_time = (
    a.appointment_time + (sub.total_minutes || ' minutes')::interval
    )::time
FROM (SELECT appointment_id, SUM(duration_minutes) AS total_minutes
      FROM appointment_service
      GROUP BY appointment_id) sub
WHERE a.appointment_id = sub.appointment_id;
select * from appointment;


-- ============================================================
--  28. SEED — PRODUCTS
-- ============================================================

INSERT INTO product (product_name, brand, unit_price)
SELECT p                                            AS product_name,
       b                                            AS brand,
       ROUND((RANDOM() * 140 + 10)::NUMERIC(10, 2), 2) AS unit_price
FROM beauty_products_name p
         CROSS JOIN brands_name b
         CROSS JOIN generate_series(1, 1667)
ORDER BY RANDOM()
LIMIT 1000;

 


UPDATE product
SET unit_price = ROUND((RANDOM() * 140 + 10)::NUMERIC(10, 2), 2)
where true;


-- ============================================================
--  29. SEED — INVENTORY
-- ============================================================

ALTER TABLE inventory
    SET UNLOGGED;

WITH product_totals AS (SELECT product_id,
                               (RANDOM() * 9997 + 3) AS total_units
                        FROM product)
INSERT
INTO inventory (product_id, location_id, quantity_on_hand)
SELECT p.product_id,
       l.location_id,
       GREATEST(1, ROUND((p.total_units * (0.5 + RANDOM()) / 2)::NUMERIC, 3))
FROM product_totals p
         JOIN LATERAL (
    SELECT location_id
    FROM company_location
    ORDER BY RANDOM()
    LIMIT (1 + FLOOR(RANDOM() * 3))::int
    ) l ON TRUE;

ALTER TABLE inventory
    SET LOGGED;


-- ============================================================
--  30. SEED — APPOINTMENT PRODUCTS
-- ============================================================

INSERT INTO appointment_product (appointment_id, product_id, quantity_used)
SELECT a.appointment_id,
       ((ROW_NUMBER() OVER (ORDER BY RANDOM()) - 1) % (SELECT MAX(product_id) FROM product)) + 1,
       ROUND((0.1 + RANDOM() * 2.9)::numeric, 3)
FROM appointment a
WHERE RANDOM() < 0.40
ON CONFLICT DO NOTHING;


-- ============================================================
--  31. SEED — INVOICES + PROMO DISCOUNTS
-- ============================================================


-- insert invoices for all completed appointments
INSERT INTO invoice (appointment_id, client_id, invoice_date, subtotal, tax, payment_method)
SELECT a.appointment_id,
       a.client_id,
       a.appointment_date              AS invoice_date,
       SUM(as2.price)                  AS subtotal,
       ROUND(SUM(as2.price) * 0.18, 2) AS tax,
       CASE
           WHEN random() < 0.60 THEN 'card'
           WHEN random() < 0.75 THEN 'cash'
           ELSE 'loyalty_points'
           END::payment_method_enum
FROM appointment a
         JOIN appointment_service as2 ON as2.appointment_id = a.appointment_id
WHERE a.status = 'completed'
GROUP BY a.appointment_id, a.client_id, a.appointment_date;

-- match valid promos (~20% of invoices)
CREATE TEMP TABLE temp_matched_promos AS
WITH invoice_company AS (SELECT i.invoice_id,
                                i.invoice_date,
                                i.subtotal,
                                cl.company_id
                         FROM invoice i
                                  JOIN appointment a ON a.appointment_id = i.appointment_id
                                  JOIN company_location cl ON cl.location_id = a.location_id
                         WHERE random() < 0.20),
     matched AS (SELECT DISTINCT ON (ic.invoice_id) ic.invoice_id,
                                                    p.promo_id,
                                                    p.discount_type,
                                                    p.discount_value,
                                                    ic.subtotal,
                                                    CASE
                                                        WHEN p.discount_type = 'percentage'
                                                            THEN ROUND(ic.subtotal * p.discount_value / 100.0, 2)
                                                        ELSE LEAST(p.discount_value, ic.subtotal)
                                                        END AS discount_amount
                 FROM invoice_company ic
                          JOIN promo_code p
                               ON p.company_id = ic.company_id
                                   AND p.valid_from <= ic.invoice_date
                                   AND p.valid_until >= ic.invoice_date
                 ORDER BY ic.invoice_id, RANDOM())
SELECT *
FROM matched;

-- apply discounts
UPDATE invoice i
SET discount_total = t.discount_amount
FROM temp_matched_promos t
WHERE i.invoice_id = t.invoice_id;

-- audit trail
INSERT INTO invoice_promo (invoice_id, promo_id)
SELECT invoice_id, promo_id
FROM temp_matched_promos
ON CONFLICT DO NOTHING;

DROP TABLE temp_matched_promos;


-- ============================================================
--  32. SEED — REVIEWS
-- ============================================================

WITH completed AS (SELECT a.appointment_id, a.client_id, a.appointment_date
                   FROM appointment a
                   WHERE a.status = 'completed'
                     AND random() < 0.50)
INSERT
INTO review (appointment_id, client_id, rating, comment, created_at)
SELECT appointment_id,
       client_id,
       rating,
       CASE
           WHEN random() < 0.30 THEN
               CASE rating
                   WHEN 5 THEN (ARRAY ['Fantastic, best salon in town!','Exceeded my expectations!',
                       'Great service, very satisfied!','Will definitely come back.',
                       'Very relaxing, highly recommend.'])[FLOOR(RANDOM() * 5 + 1)::int]
                   WHEN 4 THEN (ARRAY ['Staff was friendly and professional.','Good experience overall.',
                       'Nice atmosphere and great results.','Quick and efficient service.',
                       'Very clean and welcoming space.'])[FLOOR(RANDOM() * 5 + 1)::int]
                   WHEN 3 THEN (ARRAY ['Average service, nothing special.','A bit rushed but acceptable.',
                       'Decent but room for improvement.','Was okay, not great not bad.',
                       'Expected a bit more for the price.'])[FLOOR(RANDOM() * 5 + 1)::int]
                   WHEN 2 THEN (ARRAY ['Not what I expected.','Disappointed with the results.',
                       'Service was below average.','Staff seemed uninterested.',
                       'Would think twice before returning.'])[FLOOR(RANDOM() * 5 + 1)::int]
                   WHEN 1 THEN (ARRAY ['Would not recommend.','Very disappointed with the service.',
                       'Terrible experience overall.','Staff was rude and unprofessional.',
                       'Complete waste of money.'])[FLOOR(RANDOM() * 5 + 1)::int]
                   END
           END                                                          AS comment,
       (appointment_date + (random() * INTERVAL '7 days'))::timestamptz AS created_at
FROM (SELECT appointment_id,
             client_id,
             appointment_date,
             CASE
                 WHEN random() < 0.40 THEN 5
                 WHEN random() < 0.70 THEN 4
                 WHEN random() < 0.85 THEN 3
                 WHEN random() < 0.95 THEN 2
                 ELSE 1
                 END::SMALLINT AS rating
      FROM completed) r;


-- ============================================================
--  33. SEED — LOYALTY TRANSACTIONS + POINT SYNC
-- ============================================================

-- earning rows
INSERT INTO loyalty_transaction (client_id, appointment_id, points_earned, points_spent, created_at)
SELECT i.client_id,
       i.appointment_id,
       FLOOR(i.total)::int AS points_earned,
       0                   AS points_spent,
       (i.invoice_date + (random() * INTERVAL '1 hour'))::timestamptz
FROM invoice i
WHERE i.payment_method <> 'loyalty_points'
  AND FLOOR(i.total) > 0;

-- spending rows
INSERT INTO loyalty_transaction (client_id, appointment_id, points_earned, points_spent, created_at)
SELECT i.client_id,
       i.appointment_id,
       0                      AS points_earned,
       FLOOR(i.subtotal)::int AS points_spent,
       (i.invoice_date + (random() * INTERVAL '1 hour'))::timestamptz
FROM invoice i
WHERE i.payment_method = 'loyalty_points'
  AND FLOOR(i.total) > 0;

-- zero phantom balances
UPDATE client
SET loyalty_points = 0
where true;

-- sync net balance
UPDATE client c
SET loyalty_points = sub.net_points
FROM (SELECT client_id,
             GREATEST(0, COALESCE(SUM(points_earned), 0) - COALESCE(SUM(points_spent), 0))::int AS net_points
      FROM loyalty_transaction
      GROUP BY client_id) sub
WHERE c.client_id = sub.client_id;



-- ============================================================
--  34. SEED — SERVICE PRICE HISTORY
-- ============================================================

WITH RECURSIVE
    service_base AS (SELECT service_id,
                            price,
                            duration_minutes,
                            FLOOR(RANDOM() * 4)::INT AS change_count
                     FROM service
                     WHERE is_active = TRUE),
    price_changes AS (SELECT service_id,
                             1                                                       AS iteration,
                             change_count,
                             price::NUMERIC(10, 2)                                   AS new_price,
                             ROUND((price * 0.9)::NUMERIC, 2)::NUMERIC(10, 2)        AS old_price,
                             (NOW() - (RANDOM() * INTERVAL '6 months'))::TIMESTAMPTZ AS changed_at
                      FROM service_base
                      WHERE change_count >= 1

                      UNION ALL

                      SELECT pc.service_id,
                             pc.iteration + 1,
                             pc.change_count,
                             pc.old_price,
                             ROUND((pc.old_price * 0.9)::NUMERIC, 2)::NUMERIC(10, 2),
                             (pc.changed_at - (RANDOM() * INTERVAL '6 months'))::TIMESTAMPTZ
                      FROM price_changes pc
                      WHERE pc.iteration < pc.change_count)
INSERT
INTO service_price_history (service_id, old_price, new_price, changed_at)
SELECT service_id,
       GREATEST(old_price, 5.00),
       GREATEST(new_price, 5.00),
       changed_at
FROM price_changes;


-- ============================================================
--  35. SEED — STAFF TIME SLOTS (WITH ADJUSTABLE LIMIT)
-- ============================================================

ALTER TABLE staff_time_slot SET UNLOGGED;

INSERT INTO staff_time_slot (staff_id, slot_start)
SELECT staff_id, slot_start
FROM (SELECT sa.staff_id,
             (
                 d.slot_date
                     + sa.start_time
                     + (gs * INTERVAL '15 minutes')
                 )::timestamp AS slot_start
      FROM staff_availability sa
               JOIN generate_series(
                      CURRENT_DATE - INTERVAL '7 days',
                      CURRENT_DATE + INTERVAL '30 days',
                      INTERVAL '1 day'
                    ) AS d(slot_date)
                    ON EXTRACT(DOW FROM d.slot_date) =
                       CASE sa.day_of_week
                           WHEN 'sunday' THEN 0
                           WHEN 'monday' THEN 1
                           WHEN 'tuesday' THEN 2
                           WHEN 'wednesday' THEN 3
                           WHEN 'thursday' THEN 4
                           WHEN 'friday' THEN 5
                           WHEN 'saturday' THEN 6
                           END
               CROSS JOIN LATERAL generate_series(
              0,
              FLOOR(EXTRACT(EPOCH FROM (sa.end_time - sa.start_time)) / 900) - 1
                                  ) AS gs
      LIMIT 1000000) AS limited_slots
ON CONFLICT (staff_id, slot_start) DO NOTHING;

-- remove slots that overlap blocked_time
DELETE FROM staff_time_slot ts
WHERE EXISTS (SELECT 1
              FROM blocked_time b
              WHERE b.staff_id = ts.staff_id
                AND ts.slot_start < b.end_datetime
                AND ts.slot_start + INTERVAL '15 minutes' > b.start_datetime);

ALTER TABLE staff_time_slot SET LOGGED;