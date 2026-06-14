package com.veganmundi.account.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.HashMap;
import java.util.Map;

/**
 * Account API Endpoints
 */
@RestController
@RequestMapping("/api/account")
public class AccountController {

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        Map<String, String> response = new HashMap<>();
        response.put("service", "account-service");
        response.put("status", "UP");
        return ResponseEntity.ok(response);
    }

    @PostMapping("/register")
    public ResponseEntity<Map<String, String>> register() {
        // TODO: Implement registration logic
        Map<String, String> response = new HashMap<>();
        response.put("message", "Register endpoint stub");
        return ResponseEntity.ok(response);
    }

    @PostMapping("/login")
    public ResponseEntity<Map<String, String>> login() {
        // TODO: Implement login logic with JWT generation
        Map<String, String> response = new HashMap<>();
        response.put("message", "Login endpoint stub");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/profile")
    public ResponseEntity<Map<String, String>> getProfile() {
        // TODO: Implement profile retrieval with JWT validation
        Map<String, String> response = new HashMap<>();
        response.put("message", "Profile endpoint stub");
        return ResponseEntity.ok(response);
    }
}
