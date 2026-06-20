package com.veganmundi.account.controller;

import com.veganmundi.shared.security.JwtTokenProvider;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Account endpoints — mirrors Node.js accountRouter/accountController exactly.
 * POST /account/create  → register new account
 * POST /account/signin  → authenticate and return JWT
 */
@RestController
@RequestMapping("/account")
@CrossOrigin(origins = "*")
public class AccountController {

    @Autowired
    private JdbcTemplate jdbc;

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    private final BCryptPasswordEncoder bcrypt = new BCryptPasswordEncoder(10);

    // ── POST /account/create ──────────────────────────────────────────────────

    @PostMapping("/create")
    public ResponseEntity<?> createAccount(@RequestBody Map<String, String> body) {
        String firstName = body.get("firstName");
        String lastName  = body.get("lastName");
        String email     = body.get("email");
        String password  = body.get("password");

        String hashedPassword = bcrypt.encode(password);

        try {
            jdbc.update(
                "INSERT INTO ACCOUNT VALUES(?, ?, ?, ?)",
                email, firstName, lastName, hashedPassword
            );
            return ResponseEntity.status(HttpStatus.CREATED).body("Account created successfully");
        } catch (org.springframework.dao.DuplicateKeyException ex) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("error", "There is already an account registered with the e-mail '" + email + "'"));
        } catch (Exception ex) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "There was an error while creating your account"));
        }
    }

    // ── POST /account/signin ──────────────────────────────────────────────────

    @PostMapping("/signin")
    public ResponseEntity<?> signIn(@RequestBody Map<String, String> body) {
        String email    = body.get("email");
        String password = body.get("password");

        List<Map<String, Object>> rows = jdbc.queryForList(
            "SELECT * FROM ACCOUNT WHERE EMAIL = ?", email
        );

        if (rows.isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("error", "Invalid credentials"));
        }

        Map<String, Object> account = rows.get(0);
        String storedHash = (String) account.get("PASSWORD");

        if (!bcrypt.matches(password, storedHash)) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("error", "Invalid credentials"));
        }

        String firstName = (String) account.get("FIRST_NAME");
        String lastName  = (String) account.get("LAST_NAME");
        String token     = jwtTokenProvider.generateToken(firstName, lastName, email);

        Map<String, Object> userInfo = Map.of(
            "firstName", firstName,
            "lastName",  lastName,
            "email",     email
        );

        return ResponseEntity.ok(Map.of(
            "message",  "Signin successfull",
            "token",    token,
            "userInfo", userInfo
        ));
    }
}

