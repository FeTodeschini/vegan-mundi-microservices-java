package com.veganmundi.delivery.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Delivery endpoints — mirrors Node.js deliveryMethodsRouter/deliveryMethodsController.
 * GET /delivery-methods
 */
@RestController
@CrossOrigin(origins = "*")
public class DeliveryController {

    @Autowired
    private JdbcTemplate jdbc;

    @GetMapping("/delivery-methods")
    public ResponseEntity<?> getDeliveryMethods() {
        try {
            List<Map<String, Object>> result = jdbc.queryForList(
                "SELECT * FROM DELIVERY_METHOD ORDER BY DISPLAY_ORDER"
            );
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", e.getMessage()));
        }
    }
}
