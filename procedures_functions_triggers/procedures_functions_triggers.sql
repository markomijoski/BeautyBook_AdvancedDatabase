
--T/F na is_active
CREATE OR REPLACE PROCEDURE activate_deactivate_service(
    p_service_id INT,
    p_is_active BOOLEAN
)
    LANGUAGE plpgsql
AS
$$
BEGIN
    UPDATE service
    SET is_active = p_is_active
    WHERE service_id = p_service_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Service % does not exist.', p_service_id;
    END IF;

    RAISE NOTICE 'Service % is now %.', p_service_id,
        CASE WHEN p_is_active THEN 'active' ELSE 'inactive' END;
END;
$$;

CALL activate_deactivate_service(1, FALSE);

CALL activate_deactivate_service(1, TRUE);

CALL activate_deactivate_service(9999, TRUE);

CREATE OR REPLACE PROCEDURE confirm_appointment(
    p_appointment_id INT
)
    LANGUAGE plpgsql
AS
$$
BEGIN
    UPDATE appointment
    SET status = 'confirmed'
    WHERE appointment_id = p_appointment_id
      AND status = 'pending';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Appointment % does not exist or is not in pending status.', p_appointment_id;
    END IF;

    RAISE NOTICE 'Appointment % confirmed.', p_appointment_id;
END;
$$;

-- Confirm na pending appointment
-- (prosledi go istoto id sto ke go stavis i vo testot za complete)
CALL confirm_appointment(2751692);



CREATE OR REPLACE PROCEDURE complete_appointment(
    p_appointment_id INT
)
    LANGUAGE plpgsql
AS
$$
BEGIN
    UPDATE appointment
    SET status = 'completed'
    WHERE appointment_id = p_appointment_id
      AND status = 'confirmed';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Appointment % does not exist or is not in confirmed status.', p_appointment_id;
    END IF;

    RAISE NOTICE 'Appointment % completed.', p_appointment_id;
END;
$$;

-- Complete na confirmed appointment
CALL complete_appointment(2751692);


-- vazno e deka staff i service treba da se od ISTA company
CREATE OR REPLACE PROCEDURE add_staff_to_service(
    p_staff_id INT,
    p_service_id INT
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_exists BOOLEAN;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM staff WHERE staff_id = p_staff_id) THEN
        RAISE EXCEPTION 'Staff % does not exist.', p_staff_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM service WHERE service_id = p_service_id) THEN
        RAISE EXCEPTION 'Service % does not exist.', p_service_id;
    END IF;

    IF NOT EXISTS (SELECT 1
                   FROM staff s
                            JOIN company_location cl ON cl.location_id = s.location_id
                   WHERE s.staff_id = p_staff_id
                     AND cl.company_id = (SELECT company_id FROM service WHERE service_id = p_service_id)) THEN
        RAISE EXCEPTION 'Staff % and service % do not belong to the same company.', p_staff_id, p_service_id;
    END IF;

    --     INSERT INTO staff_service (staff_id, service_id)
--     VALUES (p_staff_id, p_service_id)
--     ON CONFLICT DO NOTHING;

    SELECT EXISTS (SELECT 1
                   FROM staff_service
                   WHERE staff_id = p_staff_id
                     AND service_id = p_service_id)
    INTO v_exists;

    IF v_exists THEN
        RAISE NOTICE 'Staff % is ALREADY assigned to service %.', p_staff_id, p_service_id;
    ELSE
        INSERT INTO staff_service (staff_id, service_id)
        VALUES (p_staff_id, p_service_id);

        RAISE NOTICE 'Staff % SUCCESSFULLY assigned to service %.', p_staff_id, p_service_id;
    END IF;

END;
$$;



CREATE OR REPLACE PROCEDURE remove_staff_from_service(
    p_staff_id INT,
    p_service_id INT
)
    LANGUAGE plpgsql
AS
$$
BEGIN
    DELETE
    FROM staff_service
    WHERE staff_id = p_staff_id
      AND service_id = p_service_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assignment between staff % and service % does not exist.',
            p_staff_id, p_service_id;
    END IF;

    RAISE NOTICE 'Staff % removed from service %.', p_staff_id, p_service_id;
END;
$$;

-- Assign
--243 company_id
--3347 location_id
--173 service_id

CALL add_staff_to_service(108615, 173);
CALL remove_staff_from_service(108615, 173);
CALL add_staff_to_service(108615, 19);

CREATE OR REPLACE FUNCTION get_appointment_total(
    p_appointment_id INT
)
    RETURNS NUMERIC(10, 2)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total NUMERIC(10, 2);
BEGIN
    SELECT COALESCE(SUM(price), 0)
    INTO v_total
    FROM appointment_service
    WHERE appointment_id = p_appointment_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Appointment % does not exist.', p_appointment_id;
    END IF;

    RETURN v_total;
END;
$$;

SELECT get_appointment_total(986317);
-- rez 85
SELECT get_appointment_total(986318);
-- rez 240

--COMPLEX

CREATE OR REPLACE PROCEDURE staff_add_blocked_time(
    p_staff_id INT,
    p_start_datetime TIMESTAMPTZ,
    p_end_datetime TIMESTAMPTZ,
    p_reason TEXT DEFAULT NULL
)
    LANGUAGE plpgsql
AS
$$
BEGIN

   
    IF p_end_datetime <= p_start_datetime THEN
        RAISE EXCEPTION 'end_datetime must be after start_datetime.';
    END IF;

 
    IF NOT EXISTS (SELECT 1
                   FROM staff s
                            JOIN "user" u ON u.user_id = s.staff_id
                   WHERE s.staff_id = p_staff_id
                     AND u.is_active = TRUE) THEN
        RAISE EXCEPTION 'Staff % does not exist or is not active.', p_staff_id;
    END IF;


    IF EXISTS (SELECT 1
               FROM blocked_time
               WHERE staff_id = p_staff_id
                 AND start_datetime < p_end_datetime
                 AND end_datetime > p_start_datetime) THEN
        RAISE EXCEPTION 'Blocked time overlaps with an existing blocked period for staff %.', p_staff_id;
    END IF;

    
    IF EXISTS (SELECT 1
               FROM appointment
               WHERE staff_id = p_staff_id
                 AND status <> 'cancelled'
                 AND (appointment_date + appointment_time)::TIMESTAMP AT TIME ZONE 'UTC' < p_end_datetime
                 AND (appointment_date + end_time)::TIMESTAMP AT TIME ZONE 'UTC' > p_start_datetime) THEN
        RAISE EXCEPTION 'Blocked time overlaps with an existing appointment for staff %.', p_staff_id;
    END IF;

  
    INSERT INTO blocked_time (staff_id, start_datetime, end_datetime, reason)
    VALUES (p_staff_id, p_start_datetime, p_end_datetime, p_reason);

    
    DELETE
    FROM staff_time_slot
    WHERE staff_id = p_staff_id
      AND appointment_id IS NULL
      AND slot_start >= (p_start_datetime AT TIME ZONE 'UTC')
      AND slot_start < (p_end_datetime AT TIME ZONE 'UTC');

END;
$$;



-- dodaj block i izbrisi (utre 12-13)
CALL staff_add_blocked_time(
        108615,
        (CURRENT_DATE + 1 + TIME '12:00')::TIMESTAMPTZ,
        (CURRENT_DATE + 1 + TIME '13:00')::TIMESTAMPTZ,
        'Personal errand'
     );

-- Test error: end before start
CALL staff_add_blocked_time(
        108615,
        (CURRENT_DATE + 1 + TIME '12:00')::TIMESTAMPTZ,
        (CURRENT_DATE + 1 + TIME '10:00')::TIMESTAMPTZ,
        NULL
     );

-- Test error: overlaps with the block we just inserted
CALL staff_add_blocked_time(
        108615,
        (CURRENT_DATE + 1 + TIME '12:30')::TIMESTAMPTZ,
        (CURRENT_DATE + 1 + TIME '12:40')::TIMESTAMPTZ,
        NULL
     );

CREATE OR REPLACE PROCEDURE client_book_appointment(
    p_client_id INT,
    p_staff_id INT,
    p_location_id INT,
    p_date DATE,
    p_time TIME,
    p_service_ids INT[]
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_total_duration INT;
    v_end_time       TIME;
    v_day_of_week    day_of_week_enum;
    v_appointment_id INT;
    v_avail_start    TIME;
    v_avail_end      TIME;
    v_company_id     INT;
BEGIN

    -- 1. Service list must not be empty
    IF p_service_ids IS NULL OR array_length(p_service_ids, 1) = 0 THEN
        RAISE EXCEPTION 'At least one service must be provided.';
    END IF;

    -- 2. Date/time must not be in the past
    IF p_date < CURRENT_DATE OR (p_date = CURRENT_DATE AND p_time <= CURRENT_TIME) THEN
        RAISE EXCEPTION 'Appointment date/time is in the past.';
    END IF;

    -- 3. Client exists and is active
    IF NOT EXISTS (SELECT 1
                   FROM client
                            JOIN "user" u ON u.user_id = client_id
                   WHERE client_id = p_client_id
                     AND u.is_active = TRUE) THEN
        RAISE EXCEPTION 'Client % does not exist or is not active.', p_client_id;
    END IF;

    -- 4. Staff exists, is active, and works at the given location
    IF NOT EXISTS (SELECT 1
                   FROM staff s
                            JOIN "user" u ON u.user_id = s.staff_id
                   WHERE s.staff_id = p_staff_id
                     AND s.location_id = p_location_id
                     AND u.is_active = TRUE) THEN
        RAISE EXCEPTION 'Staff % does not exist, is not active, or does not work at location %.', p_staff_id, p_location_id;
    END IF;

    -- 5. Resolve company_id from location
    SELECT company_id
    INTO v_company_id
    FROM company_location
    WHERE location_id = p_location_id;

    -- 6. All services valid, active, and belong to this company
    IF (SELECT COUNT(*)
        FROM service
        WHERE service_id = ANY (p_service_ids)
          AND is_active = TRUE
          AND company_id = v_company_id) <> array_length(p_service_ids, 1) THEN
        RAISE EXCEPTION 'One or more services are invalid, inactive, or do not belong to this company.';
    END IF;

    -- 7. Staff is assigned to all requested services
    IF (SELECT COUNT(*)
        FROM staff_service
        WHERE staff_id = p_staff_id
          AND service_id = ANY (p_service_ids)) <> array_length(p_service_ids, 1) THEN
        RAISE EXCEPTION 'Staff % is not assigned to one or more of the requested services.', p_staff_id;
    END IF;

    -- 8. Calculate total duration and derive end_time
    SELECT COALESCE(SUM(duration_minutes), 0)
    INTO v_total_duration
    FROM service
    WHERE service_id = ANY (p_service_ids);

    v_end_time := p_time + (v_total_duration || ' minutes')::INTERVAL;
    v_day_of_week := LOWER(TRIM(TO_CHAR(p_date, 'FMDay')))::day_of_week_enum;

    -- 9. Staff availability covers the full window
    SELECT start_time, end_time
    INTO v_avail_start, v_avail_end
    FROM staff_availability
    WHERE staff_id = p_staff_id
      AND day_of_week = v_day_of_week;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Staff % has no availability on %.', p_staff_id, v_day_of_week;
    END IF;

    IF p_time < v_avail_start OR v_end_time > v_avail_end THEN
        RAISE EXCEPTION 'Appointment window %–% falls outside staff availability %–% on %.',
            p_time, v_end_time, v_avail_start, v_avail_end, v_day_of_week;
    END IF;

    -- 10. Location is open and appointment fits within business hours
    IF NOT EXISTS (SELECT 1
                   FROM business_hours
                   WHERE location_id = p_location_id
                     AND day_of_week = v_day_of_week
                     AND is_closed = FALSE
                     AND open_time <= p_time
                     AND close_time >= v_end_time) THEN
        RAISE EXCEPTION 'Appointment window %–% falls outside business hours for location % on %.',
            p_time, v_end_time, p_location_id, v_day_of_week;
    END IF;

    -- 11. No overlap with blocked_time
    IF EXISTS (SELECT 1
               FROM blocked_time
               WHERE staff_id = p_staff_id
                 AND (p_date + p_time)::TIMESTAMP AT TIME ZONE 'UTC' < end_datetime
                 AND (p_date + v_end_time)::TIMESTAMP AT TIME ZONE 'UTC' > start_datetime) THEN
        RAISE EXCEPTION 'Time slot overlaps with a blocked period for staff %.', p_staff_id;
    END IF;

    -- 12. No overlap with existing appointments
    IF EXISTS (SELECT 1
               FROM appointment
               WHERE staff_id = p_staff_id
                 AND appointment_date = p_date
                 AND status <> 'cancelled'
                 AND appointment_time < v_end_time
                 AND end_time > p_time) THEN
        RAISE EXCEPTION 'Time slot %–% conflicts with an existing appointment for staff %.',
            p_time, v_end_time, p_staff_id;
    END IF;

    -- 13. Insert appointment
    INSERT INTO appointment (client_id, staff_id, location_id, appointment_date, appointment_time, end_time, status)
    VALUES (p_client_id, p_staff_id, p_location_id, p_date, p_time, v_end_time, 'pending')
    RETURNING appointment_id INTO v_appointment_id;

    -- 14. Snapshot services
    INSERT INTO appointment_service (appointment_id, service_id, duration_minutes, price)
    SELECT v_appointment_id, service_id, duration_minutes, price
    FROM service
    WHERE service_id = ANY (p_service_ids);

    -- 15. Mark time slots as occupied
    UPDATE staff_time_slot
    SET appointment_id = v_appointment_id
    WHERE staff_id = p_staff_id
      AND slot_start >= (p_date + p_time)::TIMESTAMP
      AND slot_start < (p_date + v_end_time)::TIMESTAMP
      AND appointment_id IS NULL;

END;
$$;

-- Valid booking:
CALL client_book_appointment(710096, 23918, 3, CURRENT_DATE + 1, '13:00', ARRAY [18, 19]);

-- Test error: date in the past
CALL client_book_appointment(710096, 23918, 3, CURRENT_DATE - 1, '10:00', ARRAY [18, 19]);

-- Test error: empty service list
CALL client_book_appointment(710096, 23918, 3, CURRENT_DATE + 1, '10:00', ARRAY []::INT[]);

-- Test error: overlapping slot (run the valid booking twice)
CALL client_book_appointment(710096, 23918, 3, CURRENT_DATE + 1, '10:00', ARRAY [18, 19]);

-- Test error: staff not assigned to service
CALL client_book_appointment(710096, 23918, 3, CURRENT_DATE + 1, '14:00', ARRAY [99]);

CREATE OR REPLACE PROCEDURE client_cancel_appointment(
    p_appointment_id INT,
    p_client_id INT,
    p_cancellation_reason TEXT DEFAULT NULL
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_rec RECORD;
BEGIN

    -- 1. Fetch appointment, verify ownership and cancellability
    SELECT a.status, a.appointment_date, a.appointment_time, a.staff_id
    INTO v_rec
    FROM appointment a
    WHERE a.appointment_id = p_appointment_id
      AND a.client_id = p_client_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Appointment % not found or does not belong to client %.',
            p_appointment_id, p_client_id;
    END IF;

    IF v_rec.status NOT IN ('pending', 'confirmed') THEN
        RAISE EXCEPTION 'Appointment % cannot be cancelled (current status: %).',
            p_appointment_id, v_rec.status;
    END IF;

    IF (v_rec.appointment_date + v_rec.appointment_time) <= (CURRENT_DATE + CURRENT_TIME) THEN
        RAISE EXCEPTION 'Appointment % has already started or passed.', p_appointment_id;
    END IF;

    -- 2. Cancel it
    UPDATE appointment
    SET status              = 'cancelled',
        cancelled_at        = NOW(),
        cancellation_reason = p_cancellation_reason
    WHERE appointment_id = p_appointment_id;

    -- 3. Free up the time slots
    UPDATE staff_time_slot
    SET appointment_id = NULL
    WHERE appointment_id = p_appointment_id;

    RAISE NOTICE 'Appointment % cancelled.', p_appointment_id;

END;
$$;

-- Cancel appointment 1 belonging to client 1
CALL client_cancel_appointment(5917661, 710096, 'Changed my mind');

-- Test error: already cancelled (run twice)
CALL client_cancel_appointment(5917661, 710096, 'Changed my mind');

-- Test error: appointment belongs to a different client or does not exist
CALL client_cancel_appointment(1, 99, NULL);

CREATE OR REPLACE PROCEDURE generate_invoice(
    p_appointment_id INT,
    p_payment_method payment_method_enum,
    p_promo_codes TEXT[] DEFAULT NULL,
    p_tax NUMERIC(10, 2) DEFAULT 0
)
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_client_id      INT;
    v_company_id     INT;
    v_subtotal       NUMERIC(10, 2);
    v_discount_total NUMERIC(10, 2) := 0;
    v_invoice_id     INT;
    v_promo          RECORD;
BEGIN

    -- 1. Appointment exists, is completed, resolve client and company
    SELECT a.client_id, cl.company_id
    INTO v_client_id, v_company_id
    FROM appointment a
             JOIN company_location cl ON cl.location_id = a.location_id
    WHERE a.appointment_id = p_appointment_id
      AND a.status = 'completed';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Appointment % does not exist or is not completed.', p_appointment_id;
    END IF;

    -- 2. No invoice already exists
    IF EXISTS (SELECT 1 FROM invoice WHERE appointment_id = p_appointment_id) THEN
        RAISE EXCEPTION 'An invoice already exists for appointment %.', p_appointment_id;
    END IF;

    -- 3. Subtotal from the appointment_service snapshot
    SELECT COALESCE(SUM(price), 0)
    INTO v_subtotal
    FROM appointment_service
    WHERE appointment_id = p_appointment_id;

    -- 4. Apply promo codes
    FOR v_promo IN
        SELECT pc.promo_id, pc.discount_type, pc.discount_value
        FROM promo_code pc
        WHERE pc.code = ANY (p_promo_codes)
          AND pc.company_id = v_company_id
          AND CURRENT_DATE BETWEEN pc.valid_from AND pc.valid_until
        LOOP
            v_discount_total := v_discount_total + CASE
                                                       WHEN v_promo.discount_type = 'percentage'
                                                           THEN ROUND(v_subtotal * (v_promo.discount_value / 100), 2)
                                                       ELSE v_promo.discount_value
                END;
        END LOOP;

    -- Cap discount at subtotal so total never goes negative
    v_discount_total := LEAST(v_discount_total, v_subtotal);

    -- 5. Insert invoice
    INSERT INTO invoice (appointment_id, client_id, invoice_date,
                         subtotal, discount_total, tax, payment_method)
    VALUES (p_appointment_id, v_client_id, CURRENT_DATE,
            v_subtotal, v_discount_total, p_tax, p_payment_method)
    RETURNING invoice_id INTO v_invoice_id;

    -- 6. Link promos to invoice
    INSERT INTO invoice_promo (invoice_id, promo_id)
    SELECT v_invoice_id, pc.promo_id
    FROM promo_code pc
    WHERE pc.code = ANY (p_promo_codes)
      AND pc.company_id = v_company_id
      AND CURRENT_DATE BETWEEN pc.valid_from AND pc.valid_until;

    RAISE NOTICE 'Invoice % created for appointment %.', v_invoice_id, p_appointment_id;

END;
$$;

-- Valid invoice: completed appointment 1, cash, no promos
CALL generate_invoice(5025426, 'cash', NULL, 0);

-- With a promo code
CALL generate_invoice(4945256, 'card', ARRAY ['SUMMER10'], 1.50);

-- Test error: invoice already exists (run twice)
CALL generate_invoice(5025426, 'cash', NULL, 0);

-- Test error: appointment not completed
CALL generate_invoice(3, 'cash', NULL, 0);



CREATE OR REPLACE PROCEDURE generate_staff_time_slots_from_to(
    p_staff_id  INT,
    p_from_date DATE,
    p_to_date   DATE
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF NOT EXISTS (
        SELECT 1 FROM staff s
        JOIN "user" u ON u.user_id = s.staff_id
        WHERE s.staff_id = p_staff_id AND u.is_active = TRUE
    ) THEN
        RAISE EXCEPTION 'Staff % does not exist or is not active.', p_staff_id;
    END IF;

    IF p_to_date < p_from_date THEN
        RAISE EXCEPTION 'p_to_date must be on or after p_from_date.';
    END IF;

    INSERT INTO staff_time_slot (staff_id, slot_start)
    SELECT p_staff_id, slot
    FROM generate_series(
        p_from_date::TIMESTAMP,
        p_to_date::TIMESTAMP + INTERVAL '1 day' - INTERVAL '15 minutes',
        INTERVAL '15 minutes'
    ) AS slot
    JOIN staff_availability sa
        ON  sa.staff_id    = p_staff_id
        AND sa.day_of_week = LOWER(TRIM(TO_CHAR(slot, 'FMDay')))::day_of_week_enum
        AND slot::TIME     >= sa.start_time
        AND slot::TIME     <  sa.end_time
    WHERE NOT EXISTS (
        SELECT 1 FROM blocked_time bt
        WHERE  bt.staff_id        = p_staff_id
          AND  bt.start_datetime <= slot
          AND  bt.end_datetime   >  slot
    )
    ON CONFLICT DO NOTHING;

    RAISE NOTICE 'Slots generated for staff % — % to %.', p_staff_id, p_from_date, p_to_date;

END;
$$;



CREATE OR REPLACE FUNCTION trg_check_appointment_conflicts()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM appointment
        WHERE staff_id           = NEW.staff_id
          AND appointment_date   = NEW.appointment_date
          AND appointment_time   = NEW.appointment_time
          AND appointment_id    <> NEW.appointment_id
          AND status            <> 'cancelled'
    ) THEN
        RAISE EXCEPTION
            'Staff member % is already booked on % at %.',
            NEW.staff_id, NEW.appointment_date, NEW.appointment_time
            USING ERRCODE = 'unique_violation';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM appointment
        WHERE client_id          = NEW.client_id
          AND appointment_date   = NEW.appointment_date
          AND appointment_id    <> NEW.appointment_id
          AND status            <> 'cancelled'
          AND NEW.appointment_time <  end_time
          AND appointment_time   <  NEW.end_time
    ) THEN
        RAISE EXCEPTION
            'Client % already has an overlapping appointment on % between % and %.',
            NEW.client_id, NEW.appointment_date, NEW.appointment_time, NEW.end_time
            USING ERRCODE = 'unique_violation';
    END IF;

    RETURN NEW;
END;
$$;




CREATE TRIGGER trg_appointment_conflicts
BEFORE INSERT OR UPDATE OF
    staff_id, client_id, appointment_date, appointment_time, end_time, status
ON appointment
FOR EACH ROW
EXECUTE FUNCTION trg_check_appointment_conflicts();


CREATE OR REPLACE FUNCTION prevent_appointment_delete()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'You can't delete appointments!';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_no_delete_appointment
BEFORE DELETE ON appointment
FOR EACH ROW
EXECUTE FUNCTION prevent_appointment_delete();
