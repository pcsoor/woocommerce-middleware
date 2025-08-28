# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Start Development
```bash
bin/dev              # Start Rails server with CSS watching via Foreman
bin/rails server     # Start Rails server only (port 3000)
```

### Testing
```bash
bundle exec rspec    # Run all RSpec tests
```

### Code Quality
```bash
bundle exec rubocop  # Run RuboCop linter
bundle exec brakeman # Run Brakeman security scanner
```

### Database
```bash
rails db:create      # Create databases
rails db:migrate     # Run migrations
rails db:seed        # Seed database
```

### Asset Compilation
```bash
bin/rails assets:precompile           # Precompile assets
bin/rails tailwindcss:watch          # Watch Tailwind CSS changes
```

### Deployment
```bash
kamal deploy         # Deploy to production using Kamal
kamal status         # Check deployment status
```

## Architecture Overview

### Core Components

**Rails Application Structure:**
- **Controllers**: Standard Rails MVC with specialized controllers for bulk operations (`bulk_price_updates_controller.rb`), product/category management, and WooCommerce store integration
- **Models**: `User`, `Store` (with encrypted API credentials), `Product`, `Category` with ActiveRecord validations and associations
- **Services**: Layered service architecture in `app/services/` for WooCommerce API interactions and business logic

**WooCommerce Integration Layer:**
- `Woocommerce::BaseClient` - Core HTTP client with special handling for `pigmentvarazs.hu` domain using system curl due to CDN/networking issues
- `Woocommerce::ProductsClient` - Product operations (CRUD, bulk updates)
- `Woocommerce::CategoriesClient` - Category management
- `ResponseWrapper` - Standardized API response handling

**Key Service Patterns:**
- `Products::FetchProducts` - Paginated product retrieval with caching
- `Products::ProcessPriceUpdates` - Bulk price update operations from CSV
- `Categories::FetchCategories` - Category synchronization
- `CsvFileProcessor` - CSV parsing and validation

### Data Flow

1. **Authentication**: Devise-based user management with encrypted store credentials
2. **WooCommerce API**: RESTful integration using consumer key/secret authentication
3. **Bulk Operations**: CSV upload → validation → background processing → results display
4. **Caching**: Product data cached using Rails caching for performance

### Special Network Configuration

The application includes custom networking for `pigmentvarazs.hu` domain:
- Uses system `curl` instead of Faraday for this specific domain
- Custom port ranges (40000-60000) and IPv6 handling
- Deployed with specific host mappings in Kamal configuration

### Internationalization

- Supports English and Hungarian (`hu` default locale)
- Time zone set to Budapest
- Uses Rails I18n with custom locale files

### Security Features

- ActiveRecord encryption for sensitive store credentials
- Brakeman security scanning integration
- URL validation with HTTPS enforcement in production
- Input sanitization for store configuration

### Background Processing

- Uses Solid Queue for background job processing
- `MergeSimpleProductsJob` for product consolidation tasks
- Runs within Puma process (`SOLID_QUEUE_IN_PUMA: true`)

## Development Notes

- The app uses Rails 8.0.2 with modern Rails features (Solid Cache, Solid Queue, Solid Cable)
- Tailwind CSS for styling with custom DaisyUI integration
- RSpec for testing with Factory Bot, WebMock, and Shoulda Matchers
- PostgreSQL for production, SQLite for development/test environments
- Kamal deployment with custom Docker configurations and PostgreSQL accessory