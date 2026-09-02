# Ahl Quran - Flutter Frontend

## 📁 Project Folder Structure

This document explains the role of each folder in the Flutter project to help developers understand the architecture.

---

## Root Level (`lib/`)

### **`bindings/`** 🔗
- **Role**: Dependency injection for GetX
- **Purpose**: Registers and initializes controllers before screens load
- **Examples**: 
  - `starter.dart` - Global controllers (auth, profile, fonts, drawer)
  - `attendance_binding.dart` - Attendance screen controllers
  - `student_management_binding.dart` - Student management controllers
  - `management_binding.dart` - Generic CRUD bindings
- **When used**: Linked to routes in `app_screens.dart` for automatic controller setup
- **Pattern**: Each binding implements `Bindings` class and defines `dependencies()` method

---

### **`controllers/`** 🎮
- **Role**: Business logic and state management (GetX controllers)
- **Purpose**: Manages app state, user interactions, data fetching
- **Key Controllers**:
  - `auth_controller.dart` - Authentication logic
  - `profile_controller.dart` - User profile state
  - `theme.dart` - Theme switching (light/dark mode)
  - `form_controller.dart` - Form field management
  - `generic_controller.dart` - Reusable CRUD operations
  - `drawer_controller.dart` - Drawer navigation state
  - `latest_acheivement.dart` - Achievement tracking
  - `subscription_information.dart` - Subscription management
- **Pattern**: Extend `GetxController`, use `.obs` for reactive state

---

### **`data/`** 📊
- **Role**: Mock/sample data for testing and demos
- **Purpose**: Provides hardcoded data structures for reports and UI testing
- **Files**:
  - `report1_data.dart` - Sample data for Report 1
  - `report2_data.dart` - Sample data for Report 2
  - `report3_data.dart` - Sample data for Report 3
  - `report4_data.dart` - Sample data for Report 4
  - `flip_card_data.dart` - Flip card demo data
- **Note**: Used for testing before real API integration

---

### **`helpers/`** 🛠️
- **Role**: Utility functions and reusable helper classes
- **Purpose**: Common functionality used across multiple screens
- **Subfolders**:
  - `reports/` - Report-specific utilities (PDF generation, formatting, table helpers)
- **Examples**: PDF generators, data transformers, report builders

---

### **`middleware/`** 🚧
- **Role**: Route guards and navigation interceptors
- **Purpose**: Controls access to routes based on conditions (auth, permissions)
- **Files**:
  - `auth_middleware.dart` - Redirects unauthenticated users to login
- **Pattern**: Extends `GetMiddleware`, implements `redirect()` method

---

### **`reports/`** 📄
- **Role**: PDF report generation logic
- **Purpose**: Builds PDF content/layouts for different report types
- **Files**:
  - `report1.dart` - PDF layout builder for Report 1
  - `report2.dart` - PDF layout builder for Report 2
  - `report3.dart` - PDF layout builder for Report 3
  - `report4.dart` - PDF layout builder for Report 4
- **Technology**: Uses `pdf` package to create printable reports
- **Pattern**: Each report has a `buildReport{N}Content()` function

---

### **`routes/`** 🗺️
- **Role**: Navigation and routing configuration
- **Purpose**: Defines all app routes and their configurations
- **Files**:
  - `app_routes.dart` - Route path constants (Routes class)
  - `app_screens.dart` - GetPage configurations with bindings
- **Pattern**: GetX routing with declarative route definitions

---

### **`screens/`** 📱
- **Role**: Top-level screen wrappers for reports
- **Purpose**: Screens that display or generate specific reports
- **Files**:
  - `report1_screen.dart` - Report 1 viewer/printer
  - `report2_screen.dart` - Report 2 viewer/printer
  - `report3_screen.dart` - Report 3 viewer/printer
  - `report4_screen.dart` - Report 4 viewer/printer
- **Note**: These are entry points for report viewing/printing

---

### **`stats/`** 📈
- **Role**: Statistical charts and data visualization screens
- **Purpose**: Display analytics, charts, and statistics
- **Files**:
  - `stat1.dart` - Student progress charts
  - `stat2.dart` - Attendance charts
  - `stat3.dart` - Performance charts
  - `chart_screen.dart` - Base chart screen layout
  - `download_button.dart` - Chart download functionality
- **Technology**: Uses Syncfusion Flutter Charts
- **Data**: Works with chart data models from `system/new_models/charts/`

---

### **`web/`** 🌐
- **Role**: Web-specific pages (marketing/landing pages)
- **Purpose**: Public-facing web pages (not app admin)
- **Subfolders**:
  - `pages/` - Home, features, pricing pages
  - `widgets/` - Web-specific UI components
  - `models/` - Web page data models
- **Note**: Separate from the admin dashboard functionality

---

## System Folder (`lib/system/`)

### **`system/models/`** ⚠️ (DEPRECATED)
- **Role**: Legacy data models
- **Subfolders**: 
  - `get/` - GET request models
  - `post/` - POST request models
- **Status**: Being replaced by `new_models/`
- **Action**: Consider removing after full migration

---

### **`system/new_models/`** 📦
- **Role**: Current data models (DTOs - Data Transfer Objects)
- **Purpose**: Defines data structures matching backend API
- **Key Files**:
  - `model.dart` - Base abstract class for all models
  - `student.dart` - Student data model
  - `guardian.dart` - Guardian data model
  - `lecture.dart` - Lecture/session data model
  - `teacher.dart` - Teacher data model
  - `supervisor.dart` - Supervisor data model
  - `exam.dart` - Exam data model
  - `appreciation.dart` - Achievement/appreciation model
  - `copy.dart` - Copy model
- **Subfolders**:
  - `forms/` - Form-specific models (dialogs, input forms)
  - `reports/` - Report data structures
  - `charts/` - Chart data models
  - `achivement_unit/` - Achievement unit models
  - `grid/` - Grid data models
- **Features**: All models implement `toJson()`, `fromJson()`, `isComplete` validation
- **Pattern**: Implements `Model` abstract class

---

### **`system/services/`** 🔌
- **Role**: API communication and external services
- **Purpose**: HTTP requests, network handling, API client
- **Files**:
  - `api_client.dart` - HTTP wrapper with auth headers, error handling
- **Subfolders**:
  - `network/` - Network-related utilities
- **Features**:
  - Automatic authentication header injection
  - Connectivity checks
  - Error handling (NoNetworkException, NoInternetException)
  - Generic CRUD operations (`fetchList`, `create`, `update`, `delete`)

---

### **`system/screens/`** 🖥️
- **Role**: Main application screens (admin/internal)
- **Purpose**: Core functionality screens (not marketing)
- **Files**:
  - `student_managment.dart` - Student CRUD operations
  - `student_managment_new.dart` - Updated student management
  - `guardian_managment.dart` - Guardian management
  - `lecture_managment.dart` - Lecture/session management
  - `achievement_managment.dart` - Achievement tracking
  - `exam_management.dart` - Exam system hub
  - `admin_dashboard.dart` - Admin control panel
  - `login.dart` - Authentication screen
  - `onboarding.dart` - First-time user onboarding
  - `dashboardScreen.dart` - Main dashboard
  - `base_layout.dart` - Common layout wrapper
- **Subfolders**:
  - `exams/` - Exam-related screens
- **Pattern**: Most use `ManagementShow` widget for CRUD grids

---

### **`system/utils/`** 🧰
- **Role**: Utility constants and helper functions
- **Purpose**: App-wide constants, themes, utilities
- **Files**:
  - `theme.dart` - Theme configuration (colors, text styles)
  - `snackbar_helper.dart` - Toast notification helpers
  - `chart_utils.dart` - Chart formatting utilities
  - `chart_download_utils.dart` - Chart export utilities
- **Subfolders**:
  - `const/` - Constants (API endpoints, form constants, etc.)

---

### **`system/widgets/`** 🧩
- **Role**: Reusable UI components
- **Purpose**: Custom widgets used throughout the app
- **Main Widgets**:
  - `custom_button.dart` - Styled button component
  - `input_field.dart` - Form input field
  - `custom_checkbox.dart` - Custom checkbox
  - `custom_container.dart` - Container wrapper
  - `drop_down.dart` - Dropdown selector
  - `search_field.dart` - Search input field
  - `picker.dart` - Date/time picker
  - `typehead.dart` - Type-ahead search
  - `multiselect.dart` - Multi-select dropdown
  - `flipcard.dart` - Animated flip card
  - `dashboardtile.dart` - Dashboard tile component
  - `header.dart` - Page header
  - `drawer.dart` - Navigation drawer
  - `footer.dart` - Page footer
  - `login.dart` - Login form widget
  - `create_account.dart` - Registration form
  - `forget_password.dart` - Password recovery form
  - `error_illustration.dart` - Error state display
  - `three_bounce.dart` - Loading animation
  - `management_show.dart` - Generic CRUD grid view
  - `management_grid.dart` - Data grid component
  - `management_buttons_menu.dart` - CRUD action buttons
  - `grid_card_button_menu.dart` - Grid card menu
  - `responsive_split_view.dart` - Responsive layout
  - `auth_layout.dart` - Authentication layout wrapper
  - `custom_matrix.dart` - Matrix view
  - `dotted_border_button.dart` - Bordered button
  - `acheivement_block.dart` - Achievement display
- **Subfolders**:
  - `dialogs/` - Modal dialog components
  - `grids/` - Data grid implementations (students, achievements, etc.)
  - `attendance/` - Attendance-specific widgets

---

## Key Files

### **`main.dart`**
- **Role**: App entry point
- **Purpose**: Initializes the Flutter app
- **Responsibilities**: 
  - Runs the app
  - May contain initialization logic

### **`app.dart`**
- **Role**: Root widget configuration
- **Purpose**: Sets up GetMaterialApp with routes, theme, bindings
- **Features**:
  - Theme configuration (light/dark mode)
  - Initial binding (`StarterBinding`)
  - Route configuration
  - Localization setup (Arabic)

### **`testpage.dart`**
- **Role**: Development/testing page
- **Purpose**: Quick navigation to all screens for testing
- **Note**: Should be removed or moved to debug folder in production

---

## Architecture Patterns

### **GetX Pattern**
- **State Management**: Controllers extend `GetxController`
- **Dependency Injection**: Bindings implement `Bindings`
- **Routing**: Declarative routes with `GetPage`
- **Reactive State**: Using `.obs` and `Obx()` widgets

### **Model Pattern**
- All models implement abstract `Model` class
- Required methods: `toJson()`, `fromJson()`, `isComplete`
- Models are DTOs matching backend API structure

### **Service Layer**
- `ApiService` handles all HTTP communication
- Centralized error handling
- Automatic authentication
- Connectivity checks before requests

### **Widget Reusability**
- Generic widgets in `system/widgets/`
- Form widgets follow consistent patterns
- Dialog system for CRUD operations

---

## Data Flow

```
User Interaction
    ↓
Widget (UI)
    ↓
Controller (Business Logic)
    ↓
Service (API Client)
    ↓
Backend API
    ↓
Model (Data Structure)
    ↓
Controller (Update State)
    ↓
Widget (Re-render)
```

---

## Common Confusion Points

### **`screens/` vs `system/screens/`**
- **`screens/`**: Report viewing screens (PDF reports)
- **`system/screens/`**: Admin/management screens (CRUD operations)

### **`system/models/` vs `system/new_models/`**
- **`system/models/`**: ⚠️ Deprecated/legacy models
- **`system/new_models/`**: ✅ Current models being used
- **Action**: Migrate fully to `new_models/` and remove `models/`

### **`data/` Purpose**
- Contains **mock data only**
- Used for testing without backend
- Should be replaced with real API calls

### **`web/` vs Admin Dashboard**
- **`web/`**: Public marketing website (home, pricing, features)
- **Admin Dashboard**: Internal app in `system/screens/`

---

## Recommended Actions

### **Cleanup**
1. ✅ Delete or archive `system/models/` after migration
2. ✅ Rename `screens/` to `report_screens/` for clarity
3. ✅ Move `testpage.dart` to a `dev/` or `debug/` folder
4. ✅ Remove mock data from `data/` after API integration

### **Organization Improvements**
1. Consider grouping related screens into feature folders
2. Add README files in major folders explaining their purpose
3. Document API endpoints in a central location
4. Create a style guide for consistent UI components

---

## Dependencies

### **Key Packages**
- `get` - State management and routing
- `http` - API communication
- `pdf` - PDF generation
- `printing` - PDF printing/preview
- `syncfusion_flutter_charts` - Charts and visualizations
- `connectivity_plus` - Network connectivity checks
- `dropdown_flutter` - Custom dropdown widgets

---

## Development Guidelines

### **Adding a New Screen**
1. Create screen in appropriate folder (`screens/` or `system/screens/`)
2. Create controller in `controllers/`
3. Create binding in `bindings/`
4. Add route constant in `routes/app_routes.dart`
5. Add GetPage in `routes/app_screens.dart` with binding
6. Create model in `system/new_models/` if needed

### **Adding a New Model**
1. Create model file in `system/new_models/`
2. Implement `Model` abstract class
3. Add `toJson()`, `fromJson()`, and `isComplete` methods
4. Add to exports in `system/new_models/` index if exists

### **Adding a New Widget**
1. Create widget in `system/widgets/`
2. Make it reusable and configurable
3. Follow existing widget patterns
4. Document parameters and usage

---

## Project Structure Tree

```
lib/
├── bindings/               # Dependency injection
├── controllers/            # Business logic (GetX)
├── data/                   # Mock data
├── helpers/                # Utility functions
├── middleware/             # Route guards
├── reports/                # PDF generators
├── routes/                 # Navigation config
├── screens/                # Report screens
├── stats/                  # Chart screens
├── web/                    # Marketing pages
├── system/
│   ├── models/            # ⚠️ Deprecated
│   ├── new_models/        # ✅ Current models
│   ├── services/          # API client
│   ├── screens/           # Admin screens
│   ├── utils/             # Constants & helpers
│   └── widgets/           # Reusable UI components
├── app.dart               # Root widget
├── main.dart              # Entry point
└── testpage.dart          # Dev testing page
```

---

## Contact & Support

For questions about the architecture or folder structure, please refer to this documentation or contact the development team.
