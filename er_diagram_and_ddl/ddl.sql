CREATE TYPE user_role_enum AS ENUM (
    'client',
    'staff',
    'owner',
    'admin'
    );

CREATE TYPE appointment_status_enum AS ENUM (
    'pending',
    'confirmed',
    'completed',
    'cancelled'
    );

CREATE TYPE staff_role_type_enum AS ENUM (
    'hairdresser',
    'nail_tech',
    'esthetician',
    'makeup_artist',
    'receptionist'
    );

CREATE TYPE discount_type_enum AS ENUM (
    'percentage',
    'fixed'
    );

CREATE TYPE payment_method_enum AS ENUM (
    'cash',
    'card',
    'loyalty_points'
    );

CREATE TYPE day_of_week_enum AS ENUM (
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
    );



CREATE TABLE company_category
(
    company_category_id SERIAL PRIMARY KEY,
    category_name       VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE company
(
    company_id  SERIAL PRIMARY KEY,
    name        VARCHAR(150) NOT NULL,
    email       VARCHAR(255) NOT NULL UNIQUE,
    phone       VARCHAR(30) UNIQUE,
    is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
    logo_url    TEXT,
    description TEXT,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE company_company_category
(
    company_id          INT NOT NULL REFERENCES company (company_id) ON DELETE CASCADE,
    company_category_id INT NOT NULL REFERENCES company_category (company_category_id) ON DELETE CASCADE,
    PRIMARY KEY (company_id, company_category_id)
);

CREATE TABLE company_location
(
    location_id SERIAL PRIMARY KEY,
    company_id  INT          NOT NULL REFERENCES company (company_id) ON DELETE CASCADE,
    address     VARCHAR(255) NOT NULL,
    city        VARCHAR(100) NOT NULL,
    phone       VARCHAR(30)
);

CREATE TABLE business_hours
(
    hours_id    SERIAL PRIMARY KEY,
    location_id INT              NOT NULL REFERENCES company_location (location_id) ON DELETE SET DEFAULT,
    day_of_week day_of_week_enum NOT NULL,
    is_closed   BOOLEAN          NOT NULL DEFAULT FALSE,
    open_time   TIME,
    close_time  TIME,
    CONSTRAINT chk_business_hours_order CHECK (close_time > open_time),
    CONSTRAINT chk_closed_times CHECK (
        (is_closed = TRUE AND open_time IS NULL AND close_time IS NULL) OR
        (is_closed = FALSE AND open_time IS NOT NULL AND close_time IS NOT NULL)
        ),
    UNIQUE (location_id, day_of_week)
);



CREATE TABLE "user"
(
    user_id           SERIAL PRIMARY KEY,
    first_name        VARCHAR(100)   NOT NULL,
    last_name         VARCHAR(100)   NOT NULL,
    email             VARCHAR(255)   NOT NULL UNIQUE,
    password_hash     TEXT           NOT NULL,
    role              user_role_enum NOT NULL,
    is_active         BOOLEAN        NOT NULL DEFAULT TRUE,
    profile_image_url TEXT,
    created_at        TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

CREATE TABLE client
(
    client_id      INT PRIMARY KEY REFERENCES "user" (user_id) ON DELETE CASCADE,
    loyalty_points INT NOT NULL DEFAULT 0 CHECK (loyalty_points >= 0),
    date_of_birth  DATE,
    phone          VARCHAR(30),
    notes          TEXT
);

CREATE TABLE owner
(
    owner_id    INT PRIMARY KEY REFERENCES "user" (user_id) ON DELETE CASCADE,
    company_id  INT  NOT NULL REFERENCES company (company_id),
    owner_since DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE staff
(
    staff_id    INT PRIMARY KEY REFERENCES "user" (user_id) ON DELETE CASCADE,
    location_id INT  NOT NULL REFERENCES company_location (location_id),
    date_hired  DATE NOT NULL DEFAULT CURRENT_DATE,
    hourly_rate NUMERIC(10, 2) CHECK (hourly_rate >= 0)
);

CREATE TABLE staff_type
(
    staff_type_id    SERIAL PRIMARY KEY,
    staff_id         INT                  NOT NULL REFERENCES staff (staff_id) ON DELETE CASCADE,
    role_type        staff_role_type_enum NOT NULL,
    specialty        VARCHAR(150),
    certification    VARCHAR(150),
    years_experience SMALLINT CHECK (years_experience >= 0),
    extra_info       TEXT,
    UNIQUE (staff_id, role_type)
);



CREATE TABLE service_category
(
    service_category_id SERIAL PRIMARY KEY,
    category_name       VARCHAR(100) NOT NULL UNIQUE,
    description         TEXT
);

CREATE TABLE service
(
    service_id          SERIAL PRIMARY KEY,
    company_id          INT            NOT NULL REFERENCES company (company_id) ON DELETE SET NULL,
    service_category_id INT            NOT NULL REFERENCES service_category (service_category_id),
    service_name        VARCHAR(150)   NOT NULL,
    duration_minutes    SMALLINT       NOT NULL CHECK (duration_minutes > 0 AND duration_minutes % 15 = 0),
    price               NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    is_active           BOOLEAN        NOT NULL DEFAULT TRUE
);

CREATE TABLE staff_service
(
    staff_id   INT NOT NULL REFERENCES staff (staff_id) ON DELETE CASCADE,
    service_id INT NOT NULL REFERENCES service (service_id) ON DELETE CASCADE,
    notes      TEXT,
    PRIMARY KEY (staff_id, service_id)
);



CREATE TABLE staff_availability
(
    availability_id SERIAL PRIMARY KEY,
    staff_id        INT              NOT NULL REFERENCES staff (staff_id) ON DELETE CASCADE,
    day_of_week     day_of_week_enum NOT NULL,
    start_time      TIME             NOT NULL,
    end_time        TIME             NOT NULL,
    CONSTRAINT chk_availability_order CHECK (end_time > start_time),
    UNIQUE (staff_id, day_of_week)
);

CREATE TABLE blocked_time
(
    block_id       SERIAL PRIMARY KEY,
    staff_id       INT         NOT NULL REFERENCES staff (staff_id) ON DELETE CASCADE,
    start_datetime TIMESTAMPTZ NOT NULL,
    end_datetime   TIMESTAMPTZ NOT NULL,
    reason         TEXT,
    CONSTRAINT chk_blocked_time_order CHECK (end_datetime > start_datetime)
);

CREATE TABLE appointment
(
    appointment_id      SERIAL PRIMARY KEY,
    client_id           INT                     NOT NULL REFERENCES client (client_id) ON DELETE SET DEFAULT,
    staff_id            INT                     NOT NULL REFERENCES staff (staff_id) ON DELETE SET DEFAULT,
    location_id         INT                     NOT NULL REFERENCES company_location (location_id) ON DELETE SET DEFAULT,
    appointment_date    DATE                    NOT NULL,
    appointment_time    TIME                    NOT NULL,
    end_time            TIME                    NOT NULL,
    status              appointment_status_enum NOT NULL DEFAULT 'pending',
    notes               TEXT,
    booked_at           TIMESTAMPTZ             NOT NULL DEFAULT NOW(),
    cancelled_at        TIMESTAMPTZ,
    cancellation_reason TEXT,
    CONSTRAINT chk_appointment_time_order CHECK (end_time > appointment_time),
    CONSTRAINT chk_cancellation CHECK (
        (status = 'cancelled' AND cancelled_at IS NOT NULL) OR
        (status <> 'cancelled' AND cancelled_at IS NULL)
        ),
    UNIQUE (staff_id, appointment_date, appointment_time)
);

CREATE TABLE appointment_service
(
    appointment_id   INT            NOT NULL REFERENCES appointment (appointment_id) ON DELETE SET DEFAULT,
    service_id       INT            NOT NULL REFERENCES service (service_id),
    duration_minutes SMALLINT       NOT NULL CHECK (duration_minutes > 0),
    price            NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    PRIMARY KEY (appointment_id, service_id)
);



CREATE TABLE product
(
    product_id    SERIAL PRIMARY KEY,
    product_name  VARCHAR(150)   NOT NULL,
    brand         VARCHAR(100),
    unit_price    NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
    reorder_level INT            NOT NULL DEFAULT 0 CHECK (reorder_level >= 0)
);

CREATE TABLE appointment_product
(
    appointment_id INT            NOT NULL REFERENCES appointment (appointment_id) ON DELETE CASCADE,
    product_id     INT            NOT NULL REFERENCES product (product_id),
    quantity_used  NUMERIC(10, 3) NOT NULL CHECK (quantity_used > 0),
    PRIMARY KEY (appointment_id, product_id)
);

CREATE TABLE inventory
(
    inventory_id     SERIAL PRIMARY KEY,
    product_id       INT            NOT NULL REFERENCES product (product_id),
    location_id      INT            NOT NULL REFERENCES company_location (location_id),
    quantity_on_hand NUMERIC(10, 3) NOT NULL DEFAULT 0 CHECK (quantity_on_hand >= 0),
    UNIQUE (product_id, location_id)
);

CREATE TABLE invoice
(
    invoice_id     SERIAL PRIMARY KEY,
    appointment_id INT                 NOT NULL UNIQUE REFERENCES appointment (appointment_id) ON DELETE RESTRICT,
    client_id      INT                 NOT NULL REFERENCES client (client_id),
    invoice_date   DATE                NOT NULL DEFAULT CURRENT_DATE,
    subtotal       NUMERIC(10, 2)      NOT NULL CHECK (subtotal >= 0),
    discount_total NUMERIC(10, 2)      NOT NULL DEFAULT 0 CHECK (discount_total >= 0),
    tax            NUMERIC(10, 2)      NOT NULL DEFAULT 0 CHECK (tax >= 0),
    total          NUMERIC(10, 2) GENERATED ALWAYS AS (subtotal + tax - discount_total) STORED,
    payment_method payment_method_enum NOT NULL
);

CREATE TABLE promo_code
(
    promo_id       SERIAL PRIMARY KEY,
    company_id     INT                NOT NULL REFERENCES company (company_id) ON DELETE CASCADE,
    code           VARCHAR(50)        NOT NULL,
    discount_type  discount_type_enum NOT NULL,
    discount_value NUMERIC(10, 2)     NOT NULL CHECK (discount_value > 0),
    valid_from     DATE               NOT NULL,
    valid_until    DATE               NOT NULL,
    CONSTRAINT chk_promo_dates CHECK (valid_until >= valid_from),
    UNIQUE (company_id, code)
);

CREATE TABLE invoice_promo
(
    invoice_id INT NOT NULL REFERENCES invoice (invoice_id) ON DELETE CASCADE,
    promo_id   INT NOT NULL REFERENCES promo_code (promo_id) ON DELETE CASCADE,
    PRIMARY KEY (invoice_id, promo_id)
);



CREATE TABLE review
(
    review_id      SERIAL PRIMARY KEY,
    appointment_id INT         NOT NULL UNIQUE REFERENCES appointment (appointment_id),
    client_id      INT         NOT NULL REFERENCES client (client_id),
    rating         SMALLINT    NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment        TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE loyalty_transaction
(
    transaction_id SERIAL PRIMARY KEY,
    client_id      INT         NOT NULL REFERENCES client (client_id),
    appointment_id INT         REFERENCES appointment (appointment_id) ON DELETE SET NULL,
    points_earned  INT         NOT NULL DEFAULT 0 CHECK (points_earned >= 0),
    points_spent   INT         NOT NULL DEFAULT 0 CHECK (points_spent >= 0),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_loyalty_nonzero CHECK (points_earned > 0 OR points_spent > 0)
);



CREATE TABLE service_price_history
(
    price_history_id SERIAL PRIMARY KEY,
    service_id       INT            NOT NULL REFERENCES service (service_id) ON DELETE CASCADE,
    old_price        NUMERIC(10, 2) NOT NULL CHECK (old_price >= 0),
    new_price        NUMERIC(10, 2) NOT NULL CHECK (new_price >= 0),
    changed_at       TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

CREATE TABLE staff_time_slot
(
    slot_id        SERIAL PRIMARY KEY,
    staff_id       INT       NOT NULL REFERENCES staff (staff_id) ON DELETE CASCADE,
    slot_start     TIMESTAMP NOT NULL,
    slot_end       TIMESTAMP GENERATED ALWAYS AS (slot_start + INTERVAL '15 minutes') STORED,
    appointment_id INT       REFERENCES appointment (appointment_id) ON DELETE SET NULL,
    CONSTRAINT chk_slot_order CHECK (slot_end > slot_start),
    UNIQUE (staff_id, slot_start)
);