# Local Development Setup Guide

This guide walks you through setting up the Vegan Mundi Java microservices project on your local machine.

## System Requirements

### Minimum Specifications
- **OS**: Windows 10+, macOS 10.15+, or Linux (Ubuntu 20.04+)
- **RAM**: 8GB minimum (16GB recommended)
- **Disk**: 20GB free space
- **CPU**: 4 cores (8+ recommended)

### Required Software

#### 1. Java Development Kit (JDK)
- **Version**: Java 17 LTS
- **Download**: https://adoptium.net/ (Eclipse Temurin) or https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html
- **Installation**:
  ```bash
  # Verify installation
  java -version
  # Expected: openjdk version "17.x.x" or similar
  ```

#### 2. Maven
- **Version**: 3.8.1+
- **Download**: https://maven.apache.org/download.cgi
- **Installation**:
  ```bash
  # Extract and add to PATH
  echo $MAVEN_HOME  # Verify installation
  mvn -version
  ```

#### 3. Docker & Docker Compose
- **Download**: https://www.docker.com/products/docker-desktop
- **Installation**: Follow Docker Desktop installer
- **Verification**:
  ```bash
  docker --version
  docker-compose --version
  ```

#### 4. Terraform
- **Version**: 1.0+
- **Download**: https://www.terraform.io/downloads.html
- **Installation**: Extract and add to PATH
- **Verification**:
  ```bash
  terraform version
  ```

#### 5. AWS CLI
- **Version**: 2.x
- **Download**: https://aws.amazon.com/cli/
- **Installation**: Follow official guide
- **Verification**:
  ```bash
  aws --version
  aws configure  # Set up credentials
  ```

#### 6. Git
- **Download**: https://git-scm.com/
- **Verification**:
  ```bash
  git --version
  ```

## Environment Setup

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/vegan-mundi-microservices-java.git
cd vegan-mundi-microservices-java
```

### 2. Configure Environment Variables

Create a `.env.local` file in the project root:

```bash
# Java/Maven
JAVA_HOME=/path/to/jdk17
MAVEN_HOME=/path/to/maven

# AWS
AWS_REGION=us-east-2
AWS_PROFILE=default  # or your profile name

# Application
APP_ENV=local
LOG_LEVEL=INFO

# Database (MySQL on EC2 or local)
DB_HOST=localhost
DB_PORT=3306
DB_NAME=vegan_mundi_dev
DB_USER=root
DB_PASSWORD=vegan_password

# Service Ports
ACCOUNT_SERVICE_PORT=8001
CLASS_SERVICE_PORT=8002
ORDER_SERVICE_PORT=8003
REVIEW_SERVICE_PORT=8004
DELIVERY_SERVICE_PORT=8005
GALLERY_SERVICE_PORT=8006
PRICE_SERVICE_PORT=8007
```

### 3. Build All Services

```bash
# Clean build all modules
mvn clean package

# Build specific service
mvn clean package -pl services/account-service

# Skip tests (faster)
mvn clean package -DskipTests
```

### 4. Set Up Local MySQL

Option A: Using Docker

```bash
# Start MySQL container
docker run -d \
  --name vegan-mundi-mysql \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=vegan_mundi_dev \
  -p 3306:3306 \
  mysql:8.0

# Verify
docker ps | grep mysql
```

Option B: Local Installation

```bash
# Install MySQL (macOS with Homebrew)
brew install mysql

# Start service
brew services start mysql

# Create database
mysql -u root -e "CREATE DATABASE vegan_mundi_dev;"
```

### 5. Run Services Locally

#### Option A: Docker Compose (Recommended for Phase 1+)

```bash
# Build all Docker images
docker-compose -f docker/docker-compose.local.yml build

# Start all services
docker-compose -f docker/docker-compose.local.yml up

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

#### Option B: Run Individual Services

Each service can be run independently:

```bash
# Terminal 1: Account Service
cd services/account-service
mvn spring-boot:run

# Terminal 2: Class Service
cd services/class-service
mvn spring-boot:run

# Terminal 3: Order Service
cd services/order-service
mvn spring-boot:run

# ... etc for other services
```

### 6. Verify Installation

```bash
# Check Java
java -version

# Check Maven
mvn -version

# Check Docker
docker ps

# Check Terraform
terraform version

# Check AWS CLI
aws s3 ls
```

## Project Build

### Build All Services
```bash
mvn clean package
```

### Build Specific Service
```bash
mvn clean package -pl services/account-service
```

### Run Tests
```bash
# All tests
mvn test

# Specific test class
mvn test -Dtest=AccountServiceTest
```

### Build Docker Images
```bash
# From service directory
cd services/account-service
docker build -t vegan-mundi-account-service:latest .

# Or use docker-compose
docker-compose build
```

## IDE Setup

### IntelliJ IDEA
1. File → Open → Select project root
2. Trust project when prompted
3. Maven should auto-detect pom.xml
4. Set Project SDK: File → Project Structure → SDK → Java 17
5. Run → Edit Configurations → Add Maven run config per service

### Visual Studio Code
1. Install Extensions:
   - Extension Pack for Java
   - Spring Boot Extension Pack
   - Docker
   - Terraform
   - AWS Toolkit

2. Open project folder
3. Command palette: `Java: Configure Classpath` (auto-configured)

### Eclipse
1. File → Import → Existing Maven Projects
2. Select root directory
3. Let Maven configure the workspace
4. Window → Show View → Maven Repositories (auto-populate)

## Troubleshooting

### Issue: Java version mismatch
```bash
# Set JAVA_HOME to JDK 17
# Windows
set JAVA_HOME=C:\Program Files\Java\jdk-17

# macOS/Linux
export JAVA_HOME=/usr/libexec/java_home -v 17
```

### Issue: Maven build fails
```bash
# Clear Maven cache
mvn clean install -U

# Check dependency tree
mvn dependency:tree
```

### Issue: Docker daemon not running
```bash
# Start Docker Desktop (GUI) or
docker daemon  # On Linux
```

### Issue: MySQL connection refused
```bash
# Check MySQL status
docker ps | grep mysql

# Or restart local MySQL
brew services restart mysql
```

### Issue: Port already in use
```bash
# Find process using port (e.g., 8001)
# Windows
netstat -ano | findstr :8001

# macOS/Linux
lsof -i :8001

# Kill process
kill -9 <PID>
```

## Next Steps

1. **Read Architecture**: See [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md)
2. **Understand Services**: See [docs/SERVICE_CONTRACTS.md](../docs/SERVICE_CONTRACTS.md)
3. **Run Locally**: Follow Docker Compose or individual service steps above
4. **Write Code**: Start with [services/shared-library](../services/shared-library)
5. **Test**: Run `mvn test` and add unit tests

## IDE Shortcuts

### IntelliJ IDEA
- Alt+Enter: Quick fix
- Ctrl+Alt+L: Reformat code
- Ctrl+Shift+F10: Run current service
- Ctrl+Shift+F9: Debug current service

### VS Code
- Shift+Alt+F: Format document
- F5: Start debugging
- Ctrl+Shift+B: Build

## Additional Resources

- [Maven Official Guide](https://maven.apache.org/guides/getting-started/)
- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Docker Documentation](https://docs.docker.com/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)

---

**Last Updated**: June 2026
