# WooCommerce Middleware

A Ruby on Rails application that provides a centralized management interface for WooCommerce stores, enabling bulk operations, product management, and store administration through a modern web interface.

## Prerequisites

- Ruby 3.2.2 or higher
- PostgreSQL 12+
- Redis (for caching and background jobs)
- Node.js (for asset compilation)

## Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd woocommerce-middleware
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env
   ```
   
   Configure the following variables in `.env`:
   ```env
   DATABASE_USER=postgres
   DATABASE_PASSWORD=your_password
   DATABASE_HOST=localhost
   DATABASE_PORT=5432
   ```

4. **Database setup**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

5. **Install JavaScript dependencies and build assets**
   ```bash
   bin/rails assets:precompile
   ```

## Development

### Running the application

```bash
# Start the Rails server
bin/rails server

# Or use the development Procfile
bin/dev
```

The application will be available at `http://localhost:3000`

### Running tests

```bash
# Run all tests
bundle exec rspec
```

### Code quality

```bash
# Run RuboCop
bundle exec rubocop

# Run Brakeman security scanner
bundle exec brakeman
```

## Configuration

### WooCommerce Store Setup

1. **Generate WooCommerce API Keys**
   - Go to your WooCommerce admin panel
   - Navigate to WooCommerce → Settings → Advanced → REST API
   - Click "Add Key"
   - Set permissions to "Read/Write"
   - Copy the Consumer Key and Consumer Secret

2. **Connect Store**
   - Sign up/login to the application
   - Navigate to the onboarding page
   - Enter your store details:
     - **API URL**: `https://yourstore.com` (your WooCommerce site URL)
     - **Consumer Key**: From WooCommerce API settings
     - **Consumer Secret**: From WooCommerce API settings

## Deployment

### Using Kamal (Recommended)

```bash
# Deploy to production
kamal deploy

# Check deployment status
kamal status
```

### Manual Deployment

1. Set production environment variables
2. Run database migrations: `RAILS_ENV=production rails db:migrate`
3. Precompile assets: `RAILS_ENV=production rails assets:precompile`
4. Start the application server
