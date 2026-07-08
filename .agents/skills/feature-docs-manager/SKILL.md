---
name: feature-docs-manager
description: Automatically create, update, and manage feature-level documentation. Keeps related documentation files in sync, and registers/indexes new or modified files in parent documents like README.md. Use this skill when you are writing documentation for new or modified features, updating database schemas, adding API endpoints, or when the user asks to document changes or keep README / roadmap files up to date.
---

# Feature Documentation Manager

This skill helps you automatically keep codebase documentation clean, structured, up-to-date, and well-indexed.

When you modify code, implement new features, or refactor existing ones, documentation can quickly go stale. This skill guides you through a process of creating targeted feature documentation, synchronizing related docs, and maintaining a centralized directory list in the parent README.

## Instructions

### 1. Identify the Scope of Changes
First, determine which feature or component is being created, modified, or deleted. 
- Identify the core classes, functions, files, or database schemas that were touched.
- Determine if this change affects existing documentation, standard guides, or project roadmaps (e.g., `next_development_roadmap.md`).

### 2. Manage Feature Documentation
Every feature should have its own dedicated documentation file under the `docs/features/` directory.

- **For New Features:**
  - Create a new markdown file named `docs/features/<feature_name_in_snake_case>.md`.
  - Structure the document clearly:
    ```markdown
    # Feature Name

    ## Overview
    A high-level explanation of what this feature does, its user value, and key workflows.

    ## Architecture & Code Structure
    List the key components, files, and services created/modified, with direct file links:
    - [class_or_file_name](file:///path/to/file)

    ## Data Model / Database Schema
    Detail any database tables, models, or columns introduced or modified by this feature.

    ## UI & User Interaction (if applicable)
    A brief description of UI elements, screens, or components, including screenshots/recordings if available.

    ## Verification / How to Test
    Steps, manual tests, or automated commands to verify that this feature works as intended.
    ```
- **For Modified Features:**
  - Locate the corresponding file in `docs/features/`.
  - Update its sections to accurately reflect the changes.
  - Maintain historical context if relevant, but ensure the current status is crystal clear.

### 3. Synchronize Related Documentation
Do not let documentation become fragmented. Check and update:
- **Development Roadmap / Backlog:** If the codebase has a roadmap file (such as `next_development_roadmap.md`), update the status of the corresponding items (e.g., moving from planned to implemented, or adding detailed implementation notes).
- **Architecture/API Docs:** Update any centralized API docs, database schema references, or architectural overview files that are affected by your changes.

### 4. Register in Parent Documentation
To ensure all documentation is easily discoverable in future sessions:
- Locate the main repository parent documentation (such as the root `README.md`).
- Ensure there is a section called `## Features & Documentation` (or similar descriptive heading).
- Add or update a relative file link pointing to the specific feature documentation file, along with a brief one-sentence description of the feature.
  - Example: `* [Audit Log](file:///Users/ahmadbasymeleh/Documents/Development/Flutter%20Projects/yayasan_finance/docs/features/audit_log.md) - Automatic database trigger auditing of transaction and project changes.`

### 5. Verify Documentation and Links
- Verify that all generated and updated files compile to valid Markdown.
- Ensure all file links use the correct syntax (`[link text](file:///absolute/path/to/file)`) and point to files that actually exist.
