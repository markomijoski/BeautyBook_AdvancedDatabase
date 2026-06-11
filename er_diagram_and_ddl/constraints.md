## Database Constraints and Data Integrity

### Company_Category
The `Company_Category` table contains company categories (e.g., Salon, Spa, Barber Shop).
* `company_category_id` is the PRIMARY KEY.
* `category_name` has a UNIQUE constraint.

### Company
The `Company` table contains basic information about companies.
* `company_id` is the PRIMARY KEY.
* `email` and `phone` have UNIQUE constraints.
* `is_active` has a DEFAULT TRUE, and `created_at` has a DEFAULT NOW().

### Company_Company_Category
An M:N relationship between companies and categories.
* Composite PRIMARY KEY (`company_id`, `company_category_id`).
* FOREIGN KEYs with `ON DELETE CASCADE` for both fields.

### Company_Location
Contains physical locations.
* `location_id` is the PRIMARY KEY.
* `company_id` is a FOREIGN KEY with `ON DELETE CASCADE`.

### Business_Hours
Defines operating hours.
* `hours_id` is the PRIMARY KEY.
* `location_id` is a FOREIGN KEY with `ON DELETE SET DEFAULT`.
* UNIQUE (`location_id`, `day_of_week`).
* CHECK constraints for logical time ordering and validation of open/closed days.

### User
Basic user data.
* `user_id` is the PRIMARY KEY.
* `email` has a UNIQUE constraint.
* `role` uses `user_role_enum`.

### Client
* `client_id` is a PRIMARY KEY and a FOREIGN KEY to `User` (ON DELETE CASCADE).
* `loyalty_points >= 0`.

### Owner
* `owner_id` is a PRIMARY KEY and a FOREIGN KEY to `User` (ON DELETE CASCADE).
* `company_id` is a FOREIGN KEY.

### Staff
* `staff_id` is a PRIMARY KEY and a FOREIGN KEY to `User` (ON DELETE CASCADE).
* `location_id` is a FOREIGN KEY.
* `hourly_rate >= 0`.

### Staff_Type
* `staff_type_id` is the PRIMARY KEY.
* `staff_id` is a FOREIGN KEY with `ON DELETE CASCADE`.
* UNIQUE (`staff_id`, `role_type`).

### Service_Category
* `service_category_id` is the PRIMARY KEY.
* `category_name` has a UNIQUE constraint.

### Service
* `service_id` is the PRIMARY KEY.
* `company_id` (ON DELETE SET NULL) and `service_category_id` are FOREIGN KEYs.
* CHECK constraints for `duration_minutes` (positive and divisible by 15) and `price >= 0`.

### Staff_Service
M:N relationship between staff and services.
* Composite PRIMARY KEY (`staff_id`, `service_id`).
* FOREIGN KEYs with `ON DELETE CASCADE`.

### Staff_Availability
* `availability_id` is the PRIMARY KEY.
* `staff_id` is a FOREIGN KEY (ON DELETE CASCADE).
* UNIQUE (`staff_id`, `day_of_week`).

### Blocked_Time
* `block_id` is the PRIMARY KEY.
* `staff_id` is a FOREIGN KEY (ON DELETE CASCADE).

### Appointment
* `appointment_id` is the PRIMARY KEY.
* `client_id`, `staff_id`, `location_id` are FOREIGN KEYs (ON DELETE SET DEFAULT).
* UNIQUE (`staff_id`, `appointment_date`, `appointment_time`).
* CHECK for time ordering and statuses.

### Appointment_Service
* Composite PRIMARY KEY (`appointment_id`, `service_id`).
* `appointment_id` (ON DELETE SET DEFAULT), `service_id` (FOREIGN KEY).

### Product
* `product_id` is the PRIMARY KEY.
* CHECK for `unit_price >= 0` and `reorder_level >= 0`.

### Appointment_Product
* Composite PRIMARY KEY (`appointment_id`, `product_id`).
* `appointment_id` (ON DELETE CASCADE), `product_id` (FOREIGN KEY).

### Inventory
* `inventory_id` is the PRIMARY KEY.
* UNIQUE (`product_id`, `location_id`).
* CHECK `quantity_on_hand >= 0`.

### Invoice
* `invoice_id` is the PRIMARY KEY.
* `appointment_id` (FOREIGN KEY, ON DELETE RESTRICT, UNIQUE).
* CHECK for financial values; `total` is calculated automatically.

### Promo_Code
* `promo_id` is the PRIMARY KEY.
* UNIQUE (`company_id`, `code`).

### Invoice_Promo
* Composite PRIMARY KEY (`invoice_id`, `promo_id`).
* `ON DELETE CASCADE` for both FOREIGN KEY fields.

### Review
* `review_id` is the PRIMARY KEY.
* UNIQUE (`appointment_id`).
* CHECK (`rating` between 1 and 5).

### Loyalty_Transaction
* `transaction_id` is the PRIMARY KEY.
* `appointment_id` (ON DELETE SET NULL).
* CHECK for positive loyalty point values.

### Service_Price_History
* `price_history_id` is the PRIMARY KEY.
* `service_id` (ON DELETE CASCADE).

### Staff_Time_Slot
* `slot_id` is the PRIMARY KEY.
* `staff_id` (ON DELETE CASCADE), `appointment_id` (ON DELETE SET NULL).
* UNIQUE (`staff_id`, `slot_start`).