# BeautyBook — Advanced Database Project

## Overview

BeautyBook is a web application designed to centralize beauty and wellness salons on a single platform. It allows clients to browse salons, book appointments, track upcoming reservations, and manage their profiles. Concurrently, salon owners and staff can seamlessly manage their services, work schedules, and client workflows.

The core of this project is a robust, highly optimized transactional **PostgreSQL database** that handles all essential business logic — from conflict-free appointment scheduling and automated invoicing to loyalty tracking and AI-powered service recommendations.

---

## Project Structure & Architecture

The project is structured into modular layers, separating schema design, core database logic, analytical optimizations, and advanced AI features. Click on the section links below to view detailed documentation and code scripts for each module:

### 🏢 [1. Database Design & Schema](er_diagram_and_ddl/)
* **Domain Models:** Contains the Entity-Relationship (ER) diagram and DDL scripts establishing the core database layers (Company, User, Service, Appointment, Financial, and Loyalty).
* *See details:* Go to the [Schema & ER Diagram folder](er_diagram_and_ddl/).

### ⚙️ [2. Stored Procedures, Functions & Triggers](procedures_functions_triggers/)
* **Database-Level Logic:** Implements all core workflows in PL/pgSQL to maintain data integrity and enforce business rules natively in the database.
* **Key Operations:** Covers booking logic (`client_book_appointment`), conflict-prevention triggers, automated invoice generation, and dynamic staff time-slot management.
* *See details:* Read the [Procedures & Triggers documentation](procedures_functions_triggers/).

### ⚡ [3. Views & Query Optimization](views_and_optimization/)
* **Performance Engineering:** Focuses on read performance using early filtering, `LATERAL JOIN` aggregations, CTEs, custom indexes, and concurrently refreshed materialized views for intensive operations like real-time schedules and financial reporting dashboards.
* *See details:* Check out the [Optimization & Views breakdowns](views_and_optimization/).

### 🤖 [4. Vector Database & AI-Powered Recommendations](vector_db/)
* **Semantic Search & Personalization:** Integrates machine learning directly into PostgreSQL. It uses **384-dimensional vector embeddings** to offer semantic service recommendations and personalized customer discovery via hybrid scoring (combining cosine similarity with service ratings and popularity).
* *See details:* Explore the [Vector DB & Recommendation module](vector_db/).

---

## Project Wiki

Comprehensive phase documentation, deeper architectural analysis, and extensive SQL breakdown attachments are fully documented and available on the project wiki hosted at FINKI's development server:

🔗 **[BeautyBook Wiki Portal](https://develop.finki.ukim.mk/projects/BeautyBook/wiki/WikiStart)**
