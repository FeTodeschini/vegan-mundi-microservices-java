# Contributing & Development Guidelines

## Branch Strategy

```
main (production)
  ├── staging (pre-production testing)
  └── develop (integration branch)
      ├── feature/account-jwt-auth
      ├── feature/class-search-optimization
      ├── bugfix/order-event-routing
      └── ... (feature branches)
```

**Workflow**:
1. Create feature branch from `develop`
2. Submit PR with tests and documentation
3. Code review + automated tests required
4. Merge to `develop` when tests pass
5. Deploy to staging for QA
6. Merge `develop` → `main` for production

## Code Style Guidelines

### Java

```java
// Use Spring Boot conventions
@RestController
@RequestMapping("/api/resource")
public class ResourceController {
    
    // Inject dependencies, don't create manually
    @Autowired
    private ResourceService service;
    
    // Clear method names
    @GetMapping("/{id}")
    public ResponseEntity<ResourceDto> getResourceById(@PathVariable Long id) {
        return ResponseEntity.ok(service.findById(id));
    }
}
```

### Naming Conventions
- **Classes**: PascalCase (AccountController)
- **Methods/Variables**: camelCase (getUserById)
- **Constants**: UPPER_SNAKE_CASE (JWT_EXPIRATION_MS)
- **Packages**: com.veganmundi.{service}.{layer}

### Error Handling
- Use custom exceptions (ResourceNotFoundException, InvalidTokenException)
- Return proper HTTP status codes
- Include error message and timestamp in response

```java
@ExceptionHandler(ResourceNotFoundException.class)
public ResponseEntity<ErrorResponse> handleNotFound(ResourceNotFoundException e) {
    return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(new ErrorResponse(e.getMessage(), LocalDateTime.now()));
}
```

### Testing

All services should have >80% code coverage:

```java
@SpringBootTest
@AutoConfigureMockMvc
class AccountControllerTest {
    
    @Autowired
    private MockMvc mockMvc;
    
    @Test
    void testLoginSuccess() throws Exception {
        // Arrange, Act, Assert
        mockMvc.perform(post("/api/account/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(jsonContent))
                .andExpect(status().isOk());
    }
}
```

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**: feat, fix, docs, style, refactor, perf, test, chore
**Example**:
```
feat(auth): implement JWT token generation

- Add JwtTokenProvider utility
- Integrate with account-service login endpoint
- Add tests for token generation and validation

Closes #123
```

## Pull Request Template

```markdown
## Description
Brief summary of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Infrastructure/deployment

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests passed
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] No breaking changes
- [ ] Tests pass locally
```

## Development Workflow

### Local Development

```bash
# 1. Create feature branch
git checkout -b feature/my-feature

# 2. Make changes (add tests!)
# ... edit files ...

# 3. Run tests locally
mvn test

# 4. Build all services
mvn clean package

# 5. Commit with good message
git commit -m "feat(service): add new functionality"

# 6. Push and create PR
git push origin feature/my-feature
# Then create PR on GitHub
```

### Before Pushing

```bash
# Format code
mvn spotless:apply

# Check for style issues
mvn checkstyle:check

# Run all tests
mvn test

# Verify build
mvn clean package

# Check for security issues
mvn dependency-check:check
```

## Service Development Checklist

When adding new feature to a service:

- [ ] Write test first (TDD)
- [ ] Implement feature in controller
- [ ] Implement service/business logic
- [ ] Add database migration (Flyway)
- [ ] Update API documentation (Swagger/OpenAPI)
- [ ] Add error handling
- [ ] Update CHANGELOG.md
- [ ] Add integration test
- [ ] Performance test (if relevant)
- [ ] Security review (especially for account-service)

## Documentation

### README Files
- Create README.md in each service directory
- Document endpoints, configuration, dependencies
- Include example requests/responses

### API Documentation
- Use Swagger annotations
- Keep OpenAPI spec updated
- Example:

```java
@GetMapping("/{id}")
@Operation(summary = "Get resource by ID")
@ApiResponse(responseCode = "200", description = "Found")
@ApiResponse(responseCode = "404", description = "Not found")
public ResponseEntity<ResourceDto> getResource(@PathVariable Long id) {
    // ...
}
```

### ADRs (Architecture Decision Records)
Document significant decisions in `docs/adr/`:
- When and why we chose a particular technology
- Trade-offs considered
- Alternative options

## Deployment Checklist

Before deploying to production:

- [ ] All tests pass
- [ ] Code review approved
- [ ] Staging deployment verified
- [ ] Database migrations tested
- [ ] Monitoring configured
- [ ] Rollback plan documented
- [ ] Release notes written
- [ ] On-call engineer notified

## Troubleshooting Guide

### Service won't start
```bash
# Check for port conflicts
netstat -ano | findstr :8001

# Check logs
cat services/account-service/logs/application.log

# Check database connection
mysql -h localhost -u vegan_user -p
```

### Tests failing
```bash
# Run with verbose output
mvn test -X

# Run single test
mvn test -Dtest=ClassName#methodName

# Clear test database
docker-compose -f docker/mysql/docker-compose.yml restart
```

### Build issues
```bash
# Clear cache
mvn clean

# Update dependencies
mvn dependency:resolve

# Check for conflicts
mvn dependency:tree
```

## Performance Considerations

- Use connection pooling (HikariCP, already configured)
- Index database queries properly
- Cache where appropriate (Redis for future phases)
- Monitor query performance with CloudWatch
- Load test before production deployment

## Security Best Practices

- Never commit secrets (use AWS Secrets Manager)
- Validate all inputs
- Use HTTPS in production
- Implement rate limiting
- Log security events
- Regular dependency updates (`mvn dependency-check:aggregate`)

## Monitoring & Alerting

Each service should have:
- Health check endpoint (`/health`)
- Metrics endpoint (`/metrics`)
- Structured logging (JSON format)
- CloudWatch alarms for anomalies

---

**Last Updated**: June 2026
