# Add these recipes to your user justfile

# Run Noggin E2E tests with proper setup
noggin-e2e:
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Change to platform repo directory
    cd ~/src/platform

    # Setup environment with nix
    nixd
    
    # Start services
    echo "Starting services..."
    dotenvx run -- ant-all-services
    
    # Wait for Noggin service to be healthy
    echo "Waiting for Noggin service to be healthy..."
    while ! curl -s http://localhost:20701/health | grep -q "OK"; do
        echo "Waiting for Noggin health check..."
        sleep 2
    done
    echo "Noggin service is healthy!"
    
    # Stop Noggin service before running tests
    echo "Stopping Noggin service to run tests independently..."
    process-compose stop noggin
    
    # Run tests
    echo "Running E2E tests..."
    nixd .#npm
    dotenvx run -- npm run --workspace gateways/noggin test:e2e
    
    echo "E2E tests complete!"

# Run a specific Noggin E2E test
noggin-e2e-test test_path:
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Change to platform repo directory
    cd ~/src/platform
    
    # Setup environment with nix
    nixd
    
    # Start services
    echo "Starting services..."
    dotenvx run -- ant-all-services
    
    # Wait for Noggin service to be healthy
    echo "Waiting for Noggin service to be healthy..."
    while ! curl -s http://localhost:20701/health | grep -q "OK"; do
        echo "Waiting for Noggin health check..."
        sleep 2
    done
    echo "Noggin service is healthy!"
    
    # Stop Noggin service before running tests
    echo "Stopping Noggin service to run tests independently..."
    process-compose stop noggin
    
    # Run specific test
    echo "Running specific E2E test: {{test_path}}..."
    nixd .#npm
    dotenvx run -- npx playwright test gateways/noggin/{{test_path}}
    
    echo "E2E test complete!"