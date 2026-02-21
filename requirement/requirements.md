# Requirements Document

## Introduction

This document outlines the requirements for a **Flutter-based Vendor Seed Distribution Management Application**. The application is designed for a single vendor organization that distributes seeds to farmers through an internal authority and staff hierarchy. The core purpose of the system is to track seed distribution to farmers and monitor yield returns, enabling the vendor to assess the effectiveness of each farmer relationship and minimize losses on limited-inventory seeds.

The application supports one party (the vendor), with authority members and internal staff managing farmer records, seed distribution logs, and yield tracking. Based on farmer behavior — specifically whether they return their yield and maintain contact with vendor authorities — each farmer is automatically classified into one of four categories: **Regular**, **Sleepy**, **Blacklist**, or **Reminder**. These classifications help the vendor make informed decisions about future seed allocations.

---

## Requirements

---

### Requirement 1: User Authentication and Role Management

**User Story:**
As a staff member or authority, I want to log in securely with my credentials so that I can access only the features and data relevant to my role within the organization.

**Acceptance Criteria:**

- WHEN a user opens the application THEN the system SHALL present a login screen requiring a username and password.
- WHEN a user enters valid credentials THEN the system SHALL authenticate the user and redirect them to a role-appropriate dashboard.
- WHEN a user enters invalid credentials THEN the system SHALL display an appropriate error message and SHALL NOT grant access.
- WHEN a user is assigned the "Authority" role THEN the system SHALL grant access to farmer management, distribution logs, yield tracking, and classification overrides.
- WHEN a user is assigned the "Internal Staff" role THEN the system SHALL grant access to farmer records, seed distribution entry, and contact logging, but SHALL restrict access to administrative and configuration features.
- WHEN a logged-in user is inactive for a defined session timeout period THEN the system SHALL automatically log the user out and redirect to the login screen.
- WHEN a user logs out THEN the system SHALL clear the session and return to the login screen.

---

### Requirement 2: Farmer Profile Management

**User Story:**
As a staff member, I want to create and manage detailed farmer profiles so that the vendor has a complete record of every farmer receiving seeds.

**Acceptance Criteria:**

- WHEN a staff member navigates to the Farmer Management section THEN the system SHALL display a searchable and filterable list of all registered farmers.
- WHEN a staff member creates a new farmer profile THEN the system SHALL require the following fields: full name, contact number, village/location, land plot details (number of plots, area per plot), and assigned crop type.
- WHEN a staff member saves a new farmer profile THEN the system SHALL store the record persistently and assign a unique farmer ID.
- WHEN a staff member edits an existing farmer profile THEN the system SHALL update the record and log the change with a timestamp and the staff member's identity.
- WHEN a staff member searches for a farmer by name, ID, or location THEN the system SHALL return matching results in real time.
- WHEN a farmer profile is viewed THEN the system SHALL display the farmer's current classification, full distribution history, yield return history, and contact log.

---

### Requirement 3: Seed Distribution Log Management

**User Story:**
As a staff member, I want to log every seed distribution event against a farmer's profile so that there is a complete and traceable record of all seeds distributed by the vendor.

**Acceptance Criteria:**

- WHEN a staff member records a seed distribution THEN the system SHALL require: farmer ID, seed type, quantity distributed, date of distribution, and the staff member recording the entry.
- WHEN a distribution entry is saved THEN the system SHALL attach it to the respective farmer's profile and update the vendor's overall distribution ledger.
- WHEN a distribution is logged THEN the system SHALL automatically calculate and record the expected yield return date based on the crop type's known growing period.
- WHEN a staff member views the distribution log THEN the system SHALL display all past distributions with filters for date range, seed type, farmer, and status (yield returned / pending / overdue).
- WHEN a distribution entry is created THEN the system SHALL NOT allow deletion; only amendments with a reason and authority approval SHALL be permitted, to maintain log integrity.

---

### Requirement 4: Yield Return Tracking

**User Story:**
As an authority member, I want to track whether farmers have returned their yield after the growing period ends so that I can assess each farmer's reliability and protect the vendor from losses.

**Acceptance Criteria:**

- WHEN the system calculates that a crop's growing period has elapsed for a given distribution THEN the system SHALL mark that distribution's yield return status as "Due".
- WHEN a staff member records a yield return against a distribution THEN the system SHALL log the quantity returned, date of return, and the staff member recording the entry.
- WHEN the full yield is returned by the farmer THEN the system SHALL mark the distribution as "Fulfilled".
- WHEN a farmer returns partial yield THEN the system SHALL mark the distribution as "Partially Fulfilled" and record the outstanding quantity.
- WHEN no yield is returned and the due date has passed THEN the system SHALL mark the distribution as "Overdue" and flag the farmer for classification review.
- WHEN yield return history is viewed for a farmer THEN the system SHALL display a summary of total seeds distributed, total yield returned, and any outstanding amounts.

---

### Requirement 5: Farmer Classification System

**User Story:**
As an authority member, I want the system to automatically classify farmers into defined categories based on their yield return behavior and contact history so that I can make informed decisions about future seed allocations.

**Acceptance Criteria:**

- WHEN all plots associated with a farmer have completed their growing period AND the farmer has returned all yield to the vendor THEN the system SHALL classify that farmer as **Regular**.
- WHEN all plots associated with a farmer have completed their growing period AND the farmer has returned yield BUT the farmer has had no contact with any authority or staff member for the last 20–30 days THEN the system SHALL classify that farmer as **Sleepy**.
- WHEN a farmer has received seeds AND has not returned any yield AND has had no contact with authority or staff for the last 20–30 days after all plots' growing periods have elapsed THEN the system SHALL classify that farmer as **Blacklist**.
- WHEN a farmer has received seeds AND has not returned yield BUT is actively in contact with authority or staff within the last 20–30 days after all plots' growing periods have elapsed THEN the system SHALL classify that farmer as **Reminder**.
- WHEN a farmer's classification is computed THEN the system SHALL base the contact window calculation on the specific crop type's growing period associated with each plot.
- WHEN a farmer's classification changes THEN the system SHALL log the previous classification, the new classification, the date of change, and the triggering condition.
- WHEN an authority member reviews a farmer's classification THEN the system SHALL allow a manual override with a mandatory reason field, which SHALL be logged for audit purposes.
- WHEN the dashboard is loaded THEN the system SHALL display a summary count of farmers in each classification category.

---

### Requirement 6: Contact Log Management

**User Story:**
As a staff member, I want to log every interaction or contact made with a farmer so that the system can accurately determine the farmer's contact status for classification purposes.

**Acceptance Criteria:**

- WHEN a staff member logs a contact event for a farmer THEN the system SHALL record the date, time, contact method (call, visit, message), a brief note, and the staff member's identity.
- WHEN a contact log entry is saved THEN the system SHALL update the farmer's "last contact date" field used for classification calculations.
- WHEN a staff member views a farmer's contact history THEN the system SHALL display all logged interactions in reverse chronological order.
- WHEN no contact has been logged for a farmer for 20 days after all their plots' growing periods have ended THEN the system SHALL generate an internal alert for the assigned authority member.
- WHEN no contact has been logged for a farmer for 30 days after all their plots' growing periods have ended THEN the system SHALL escalate the alert and trigger a classification review.

---

### Requirement 7: Dashboard and Reporting

**User Story:**
As an authority member, I want a comprehensive dashboard and reporting tools so that I can monitor the overall health of seed distribution operations and take timely action.

**Acceptance Criteria:**

- WHEN an authority member opens the dashboard THEN the system SHALL display: total farmers registered, seeds distributed (total and by type), yield return rate, and a breakdown of farmers by classification category.
- WHEN the dashboard is displayed THEN the system SHALL highlight farmers whose yield is overdue or who are approaching the classification change threshold.
- WHEN an authority member generates a report THEN the system SHALL support filters for date range, farmer category, seed type, village/location, and staff member.
- WHEN a report is generated THEN the system SHALL allow it to be exported as a PDF or CSV file.
- WHEN the authority views the Blacklist report THEN the system SHALL display all blacklisted farmers with their total outstanding yield quantities and last known contact date.
- WHEN the authority views the Reminder report THEN the system SHALL display all reminder-category farmers with their contact history and outstanding yield, sorted by urgency.

---

### Requirement 8: Crop Type and Growing Period Configuration

**User Story:**
As an authority member, I want to configure crop types and their associated growing periods so that the system can accurately compute yield due dates and classification timelines.

**Acceptance Criteria:**

- WHEN an authority member navigates to the configuration section THEN the system SHALL display a list of all configured crop types with their growing period durations.
- WHEN an authority member adds a new crop type THEN the system SHALL require a crop name and growing period in days.
- WHEN an authority member edits a crop type's growing period THEN the system SHALL update the growing period and recalculate affected yield due dates, with a notification to relevant staff.
- WHEN a crop type is assigned to a farmer's plot during distribution logging THEN the system SHALL use that crop's configured growing period for all date calculations related to that distribution.
- WHEN a crop type that is in active use is deleted THEN the system SHALL prevent deletion and display an appropriate warning message.

---

### Requirement 9: Notifications and Alerts

**User Story:**
As a staff member or authority, I want to receive timely in-app notifications and alerts so that I can act promptly on pending yields, overdue farmers, and classification changes.

**Acceptance Criteria:**

- WHEN a farmer's yield due date is approaching within 7 days THEN the system SHALL send an in-app notification to the assigned staff member.
- WHEN a farmer's yield becomes overdue THEN the system SHALL send an alert to both the assigned staff member and the authority.
- WHEN a farmer's classification changes automatically THEN the system SHALL notify the authority with the farmer's name, previous classification, and new classification.
- WHEN a farmer enters the contact warning window (20 days without contact after plot completion) THEN the system SHALL notify the responsible staff member.
- WHEN a user opens the application THEN the system SHALL display a notification badge indicating the number of unread alerts.
- WHEN a user dismisses or acts on a notification THEN the system SHALL mark it as resolved and remove it from the active alerts list.

---

### Requirement 10: Data Persistence and Offline Support

**User Story:**
As a staff member operating in areas with limited connectivity, I want the application to work offline and sync when connectivity is restored so that field operations are never interrupted.

**Acceptance Criteria:**

- WHEN the device has no internet connectivity THEN the system SHALL allow staff to view existing farmer records, log distributions, and log contact events in offline mode.
- WHEN connectivity is restored THEN the system SHALL automatically sync all offline-entered data to the central database.
- WHEN a sync conflict occurs (e.g., the same record was modified by two users while offline) THEN the system SHALL flag the conflict and prompt an authority member to resolve it manually.
- WHEN data is stored locally on the device THEN the system SHALL encrypt the local database to protect farmer and vendor information.
- WHEN the application is opened THEN the system SHALL display a sync status indicator showing the last successful sync timestamp.
