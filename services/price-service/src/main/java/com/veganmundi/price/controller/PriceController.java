package com.veganmundi.price.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Price endpoints — mirrors Node.js priceRouter/priceController.
 * GET /prices
 */
@RestController
@CrossOrigin(origins = "*")
public class PriceController {

    @Autowired
    private JdbcTemplate jdbc;

    @GetMapping("/prices")
    public ResponseEntity<?> getPrices() {
        try {
            List<Map<String, Object>> result = jdbc.queryForList("SELECT * FROM PRICE");
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", e.getMessage()));
        }
    }
}
