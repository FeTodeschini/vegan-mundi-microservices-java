# Development Environment Configuration

## Quick Start (5 minutes)

```bash
# Clone repository
git clone https://github.com/your-org/vegan-mundi-microservices-java.git
cd vegan-mundi-microservices-java

# Start local MySQL service (native installation)
# macOS
brew services start mysql

# Windows (Service name may vary)
net start MySQL80

# Build all services
mvn clean package

# Start each service (in separate terminals)
java -jar services/account-service/target/vegan-mundi-account-service-1.0.0-SNAPSHOT.jar
java -jar services/class-service/target/vegan-mundi-class-service-1.0.0-SNAPSHOT.jar
java -jar services/order-service/target/vegan-mundi-order-service-1.0.0-SNAPSHOT.jar
# ... etc

# Test health check
curl http://localhost:8001/health
```

## Detailed Setup

### 1. Prerequisites

- **Java 17 LTS**: `java -version` → `openjdk 17.x.x`
- **Maven 3.8.1+**: `mvn -version`
- **Docker**: `docker --version`
- **MySQL 8.0**: Local/native installation
- **Git**: `git --version`
- **AWS CLI v2** (optional, for deployments): `aws --version`

### 2. Install Java 17

**Windows (via Chocolatey)**:
```powershell
choco install openjdk17
```

**macOS (via Homebrew)**:
```bash
brew install openjdk@17
```

**Linux (Ubuntu/Debian)**:
```bash
sudo apt-get install openjdk-17-jdk
```

### 3. Install Maven 3.9.1

**Windows**:
1. Download: https://archive.apache.org/dist/maven/maven-3/3.9.1/binaries/apache-maven-3.9.1-bin.zip
2. Extract to `C:\Program Files\apache-maven-3.9.1`
3. Add `C:\Program Files\apache-maven-3.9.1\bin` to PATH

**macOS/Linux**:
```bash
brew install maven  # or download and extract as above
```

### 4. Verify Installation

```bash
java -version     # Should show Java 17
mvn -version      # Should show Maven 3.9.1
```

### 5. Set Environment Variables

**Windows (PowerShell)**:
```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.x.x"
$env:M2_HOME = "C:\Program Files\apache-maven-3.9.1"
$env:PATH += ";$env:M2_HOME\bin"
```

**macOS/Linux (bash/zsh)**:
```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export M2_HOME=/opt/maven
export PATH=$PATH:$M2_HOME/bin
```

### 6. Clone Repository

```bash
git clone https://github.com/your-org/vegan-mundi-microservices-java.git
cd vegan-mundi-microservices-java
```

### 7. Start MySQL

```bash
# Start local MySQL service (examples)
# macOS
brew services start mysql

# Linux (systemd)
sudo systemctl start mysql

# Windows (Service name may vary)
net start MySQL80

# Connect to MySQL (password: vegan_password)
mysql -h 127.0.0.1 -u vegan_user -p

# List databases
SHOW DATABASES;
USE vegan_mundi_dev;
SHOW TABLES;
```

### 8. Build Project

```bash
# Full build (runs tests)
mvn clean package

# Build skipping tests (faster)
mvn clean package -DskipTests

# Build specific module
mvn clean package -pl services/account-service

# Run specific tests
mvn test -Dtest=AccountServiceTest
```

### 9. Start Services Individually

**Terminal 1 - Account Service**:
```bash
java -jar services/account-service/target/vegan-mundi-account-service-1.0.0-SNAPSHOT.jar \
  --server.port=8001 \
  --spring.datasource.url=jdbc:mysql://localhost:3306/vegan_mundi_dev \
  --spring.datasource.username=vegan_user \
  --spring.datasource.password=vegan_password
```

**Terminal 2 - Class Service**:
```bash
java -jar services/class-service/target/vegan-mundi-class-service-1.0.0-SNAPSHOT.jar \
  --server.port=8002 \
  --spring.datasource.url=jdbc:mysql://localhost:3306/vegan_mundi_dev
```

**Terminal 3 - Order Service**:
```bash
java -jar services/order-service/target/vegan-mundi-order-service-1.0.0-SNAPSHOT.jar \
  --server.port=8003 \
  --spring.datasource.url=jdbc:mysql://localhost:3306/vegan_mundi_dev
```

### 10. Test Services

```bash
# Health checks
curl http://localhost:8001/health
curl http://localhost:8002/health
curl http://localhost:8003/health

# API endpoints (examples)
curl -X GET http://localhost:8001/api/account/profile
curl -X GET http://localhost:8002/api/classes
curl -X POST http://localhost:8003/api/orders \
  -H "Content-Type: application/json" \
  -d '{"classId":"123","userId":"user-1"}'

# Swagger UI (if enabled)
# http://localhost:8001/swagger-ui.html
```

## IDE Setup

### IntelliJ IDEA

1. **Open Project**:
   - File → Open
   - Select `vegan-mundi-microservices-java` directory
   - Choose "Open as Project"

2. **Configure JDK**:
   - File → Project Structure
   - Select Java 17 (Downloads if needed)

3. **Enable Annotation Processing**:
   - Settings → Build, Execution, Deployment → Compiler → Annotation Processors
   - Check "Enable annotation processing"

4. **Maven Integration**:
   - Maven window auto-loads (View → Tool Windows → Maven)
   - Right-click project → Maven → Reload Projects

5. **Run Service**:
   - Right-click `AccountApplication.java`
   - Select "Run"

### Visual Studio Code

1. **Extensions**:
   ```
   - Extension Pack for Java (Microsoft)
   - Spring Boot Extension Pack (Pivotal)
   - Lombok Annotations (GaEL Domingues)
   - Markdown All in One
   ```

2. **Open Project**:
   - File → Open Folder
   - Select `vegan-mundi-microservices-java`

3. **Run Configuration** (`.vscode/launch.json`):
   ```json
   {
     "version": "0.2.0",
     "configurations": [
       {
         "name": "Account Service",
         "type": "java",
         "name": "Run AccountApplication",
         "request": "launch",
         "mainClass": "com.veganmundi.account.AccountApplication",
         "projectName": "account-service",
         "args": "--server.port=8001"
       }
     ]
   }
   ```

4. **Debug**:
   - Press F5 to debug with breakpoints
   - View logs in Debug Console

## Database Migrations

Each service uses **Flyway** for schema versioning.

```bash
# Migration files location
services/account-service/src/main/resources/db/migration/V1__Initial.sql
services/account-service/src/main/resources/db/migration/V2__Add_profiles_table.sql

# Flyway runs automatically on `mvn spring-boot:run`

# Manual migration
mvn flyway:migrate -pl services/account-service
```

## Troubleshooting

### Maven Build Fails
```bash
# Clear Maven cache
rm -rf ~/.m2/repository

# Rebuild
mvn clean package
```

### MySQL Connection Refused
```bash
# Check local MySQL service status
# macOS
brew services list | grep mysql

# Linux
sudo systemctl status mysql

# Windows
sc query MySQL80
```

### Port Already in Use
```bash
# Kill process on port 8001 (macOS/Linux)
lsof -i :8001 | grep LISTEN | awk '{print $2}' | xargs kill -9

# Windows
netstat -ano | findstr :8001
taskkill /PID <PID> /F
```

### Services Not Communicating
1. Check service is running: `curl http://localhost:8001/health`
2. Check Spring Boot logs for errors
3. Verify MySQL connection string
4. Check firewall/network settings

### Tests Failing
```bash
# Run tests with verbose output
mvn test -X

# Run single test class
mvn test -Dtest=AccountServiceTest#testLogin
```

## Building Docker Images

```bash
# Build account-service image
docker build -t vegan-mundi-account-service:latest services/account-service/

# Run container
docker run -p 8001:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/vegan_mundi_dev \
  vegan-mundi-account-service:latest

# Use docker-compose (local dev with all services)
# TODO: Create docker-compose-dev.yml with all 7 services
```

## Useful Maven Commands

```bash
# List all modules
mvn modules:list

# Compile only (no test)
mvn compile

# Run specific service
mvn spring-boot:run -pl services/account-service

# Skip tests during build
mvn clean package -DskipTests

# Generate project site
mvn site

# Check dependency tree
mvn dependency:tree -pl services/account-service
```

## Local Development Workflow

1. **Start MySQL**:
   ```bash
   # Start local MySQL service using your OS service manager
   ```

2. **Build all services**:
   ```bash
   mvn clean package -DskipTests
   ```

3. **Start services in tabs/tmux**:
   ```bash
   # Terminal 1
   java -jar services/account-service/target/vegan-mundi-account-service-1.0.0-SNAPSHOT.jar --server.port=8001
   
   # Terminal 2
   java -jar services/class-service/target/vegan-mundi-class-service-1.0.0-SNAPSHOT.jar --server.port=8002
   
   # Terminal 3
   java -jar services/order-service/target/vegan-mundi-order-service-1.0.0-SNAPSHOT.jar --server.port=8003
   ```

4. **Run tests**:
   ```bash
   mvn test
   ```

5. **Check code quality** (optional):
   ```bash
   mvn checkstyle:check
   ```

---

**Interview Talking Point**: "I set up a polyglot microservices environment locally, demonstrating understanding of service-to-service networking, database migrations, and containerization patterns."

**Last Updated**: June 2026
