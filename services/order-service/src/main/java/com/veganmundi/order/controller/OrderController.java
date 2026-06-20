package com.veganmundi.order.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.sql.Timestamp;
import java.util.Date;
import java.util.List;
import java.util.Map;

/**
 * Order endpoints — mirrors Node.js orderRouter/orderController exactly.
 * POST /order/add
 */
@RestController
@RequestMapping("/order")
@CrossOrigin(origins = "*")
public class OrderController {

    @Autowired
    private JdbcTemplate jdbc;

    // ── POST /order/add ───────────────────────────────────────────────────────

    @PostMapping("/add")
    public ResponseEntity<?> addOrder(@RequestBody Map<String, Object> body) {
        String orderNumber = (String) body.get("orderNumber");
        String email       = (String) body.get("email");
        List<?> classes    = (List<?>) body.get("classes");

        if (classes == null || classes.isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("error", "Invalid input for /order/add: expecting a non-empty array."));
        }

        try {
            // Insert order
            jdbc.update(
                "INSERT INTO `ORDER` (ORDER_NUMBER, EMAIL, PAYMENT_METHOD_ID, ORDER_DATE) VALUES (?, ?, 'CRC', NOW())",
                orderNumber, email
            );

            // Insert order classes (batch)
            Timestamp now = new Timestamp(new Date().getTime());
            for (Object item : classes) {
                @SuppressWarnings("unchecked")
                Map<String, Object> c = (Map<String, Object>) item;
                jdbc.update(
                    "INSERT INTO ORDER_CLASS (ORDER_NUMBER, EMAIL, CLASS_ID, DELIVERY_METHOD_ID, NUM_STUDENTS, PRICE, DISCOUNT_PERCENTAGE, CLASS_DATE, PURCHASE_DATE) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    c.get("ORDER_NUMBER"),
                    c.get("EMAIL"),
                    c.get("CLASS_ID"),
                    c.get("DELIVERY_METHOD_ID"),
                    c.get("NUM_STUDENTS"),
                    c.get("PRICE"),
                    c.get("DISCOUNT_PERCENTAGE"),
                    c.get("CLASS_DATE"),
                    now
                );
            }

            return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "message",     "Order added successfully",
                "orderNumber", orderNumber,
                "email",       email
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "We apologize. Your order could not be completed. " + e.getMessage()));
        }
    }
}

