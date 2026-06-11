## Additional Description

The database is structured into several logical layers, enabling comprehensive management of a single salon or a network of salons. The foundational layer consists of the `Company`, `Company_Location`, and `Company_Category` tables. The `Business_Hours` table defines operating hours for each location individually.

The user management system is built upon the `User` table, with specialized subtypes through the `Client`, `Owner`, and `Staff` tables.

- The `Staff_Type` table defines staff profiles (e.g., hairdresser, beautician) using the `staff_role_type_enum` enum type.
- `Staff_Availability` and `Blocked_Time` are critical for managing the work calendar, storing periods when staff are available for booking, as well as periods of absence or unavailability.

The services section is defined through `Service` and `Service_Category`.

- The `Staff_Service` table links staff members to the services they provide.
- `Service_Price_History` maintains all historical price changes, enabling accurate calculation and revenue analysis across different time periods.

The booking process is centralized in the `Appointment` table, linking clients, staff, and locations.

- The appointment status is defined via `appointment_status_enum`.
- For searching free slots, the `Staff_Time_Slot` table allows for precise scheduling based on service duration and staff availability.
- The `Appointment_Service` table allows for multiple services to be included in a single appointment.

The financial and loyalty layer is covered by:

- `Invoice`: Generates the final bill for the appointment, including the application of `Promo_Code`.
- `Inventory` and `Appointment_Product`: Enable tracking of products and consumables used during the appointment, as well as inventory management.
- `Review`: Allows clients to rate their experience and service quality.
- `Loyalty_Transaction`: Represents a system for tracking client points status.