## Overview of Procedures, Functions, and Triggers

### Procedures

- **`activate_deactivate_service`**: Updates the `is_active` status of a specific service. Includes a check to throw an exception if the service ID does not exist.
- **`confirm_appointment`**: Transitions an appointment status from 'pending' to 'confirmed'. Used by management/reception to validate new bookings while preventing confirmation of invalid or already processed entries.
- **`complete_appointment`**: Updates the appointment status to 'completed' once the service is finished, marking it as ready for invoicing.
- **`add_staff_to_service`**: Links a staff member to a service. Includes business logic to ensure both the staff member and service belong to the same company before recording the link.
- **`remove_staff_from_service`**: Removes the link between a staff member and a service when the service is no longer offered by that individual.
- **`staff_add_blocked_time`**: Allows inserting non-working time (breaks, leaves) into the staff calendar. It automatically checks for overlaps with existing blocks or appointments; if valid, it removes corresponding `staff_time_slot` entries and adds a record to `blocked_time`.
- **`client_book_appointment`**: The core logic for booking. Performs complex validation: checks if the date is in the future, if the staff works at the location, if the location is open, and verifies no overlaps with other appointments or blocks. It then registers the appointment and reserves the time slots.
- **`client_cancel_appointment`**: Cancels a booked or confirmed appointment. It verifies the owner, updates the status to 'cancelled', and automatically releases the time slots for new reservations.
- **`generate_invoice`**: Automatically generates a final invoice for a completed appointment. Calculates the total, applies valid promo codes (ensuring discounts do not exceed the total), adds tax, and logs the payment method.
- **`generate_staff_time_slots_from_to`**: Generates time slots for staff over a defined period. It considers only the days and hours the staff is available according to their schedule, skipping predefined blocked times.

### Functions

- **`get_appointment_total`**: Calculates and returns the total amount for an appointment based on the prices of all services recorded at that moment.

### Triggers (Functions & Triggers)

- **`trg_check_appointment_conflicts` (Function) / `trg_appointment_conflicts` (Trigger)**: Activated before any insert or update on the `appointment` table. Prevents double-booking staff and temporal overlaps for the same client on a given date by throwing an error if a conflict is detected.
- **`prevent_appointment_delete` (Function) / `trg_no_delete_appointment` (Trigger)**: Activated before any attempt to delete an `appointment` to prevent the loss of critical business and historical data.