#!/bin/bash
set -e

echo "🚀 Starting OpenFlights..."

# Wait for PostgreSQL
echo "⏳ Waiting for database..."
until pg_isready -h openflights_db -p 5432 -U user > /dev/null 2>&1; do
  sleep 1
done
echo "✅ Database ready!"

# Create database.yml with correct settings
echo "🔧 Configuring database..."
cat > config/database.yml <<EOL
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  host: openflights_db
  port: 5432
  username: user
  password: password

development:
  <<: *default
  database: openflights

test:
  <<: *default
  database: openflights_test

production:
  <<: *default
  database: openflights_production
EOL

# Fix JavaScript dependencies for compatibility
echo "📦 Updating JavaScript dependencies..."
yarn remove axios 2>/dev/null || true
yarn add axios@0.27.2 --exact 2>/dev/null || echo "Axios already compatible"

# Set up database (only for app container, not sidekiq)
if [ "$1" = "rails" ]; then
  echo "📊 Setting up database..."
  bundle exec rails db:create 2>/dev/null || echo "Database already exists"
  bundle exec rails db:migrate
fi

echo "🎉 Setup complete! Starting application..."
exec "$@"