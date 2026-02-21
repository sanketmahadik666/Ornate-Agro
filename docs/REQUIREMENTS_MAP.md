# Requirements → Code Map (context-window efficient)

Use this to open only the files needed for each requirement.

| Req | Title | Key paths |
|-----|--------|-----------|
| **1** | User Authentication & Role Management | `lib/features/auth/`, `lib/core/constants/app_constants.dart` (session timeout) |
| **2** | Farmer Profile Management | `lib/features/farmers/`, `lib/shared/domain/entities/farmer_entity.dart`, `lib/core/utils/id_generator.dart` |
| **3** | Seed Distribution Log | `lib/features/distribution/`, `lib/shared/domain/entities/distribution_entity.dart` |
| **4** | Yield Return Tracking | `lib/features/yield_tracking/`, `distribution_entity.dart` (YieldReturnStatus) |
| **5** | Farmer Classification | `lib/shared/domain/entities/farmer_entity.dart` (FarmerClassification), classification logic in `lib/features/classification/` or farmers |
| **6** | Contact Log | `lib/features/contact_log/`, `app_constants.dart` (20/30 days) |
| **7** | Dashboard & Reporting | `lib/features/dashboard/`, `lib/features/reports/` |
| **8** | Crop Type Config | `lib/features/crop_config/`, `lib/shared/domain/entities/crop_type_entity.dart` |
| **9** | Notifications & Alerts | `lib/features/notifications/`, `app_constants.dart` |
| **10** | Data Persistence & Offline | `lib/core/data/` (database, sync), secure storage |

## Directory structure

```
lib/
├── main.dart
├── app/                    # Bootstrap, MaterialApp, routes
├── core/                   # Theme, routes, constants, utils, data (DB/sync)
├── features/               # One folder per requirement/feature
│   ├── auth/               # Req 1
│   ├── farmers/            # Req 2 (+ classification Req 5)
│   ├── distribution/       # Req 3
│   ├── yield_tracking/     # Req 4
│   ├── contact_log/        # Req 6
│   ├── dashboard/          # Req 7
│   ├── crop_config/        # Req 8
│   ├── notifications/      # Req 9
│   └── reports/            # Req 7 (export)
└── shared/                 # Entities used by multiple features
    └── domain/entities/
```

## Per-feature layout

Each feature can follow:

- `data/` — repositories, local/remote datasources
- `domain/` — entities, use cases (optional)
- `presentation/` — bloc/cubit, pages, widgets
