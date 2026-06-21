package com.veganmundi.order.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;
import software.amazon.awssdk.services.eventbridge.EventBridgeClient;
import software.amazon.awssdk.services.eventbridge.model.PutEventsRequest;
import software.amazon.awssdk.services.eventbridge.model.PutEventsRequestEntry;

import java.math.BigDecimal;
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

    private static final Logger log = LoggerFactory.getLogger(OrderController.class);
    private static final ObjectMapper mapper = new ObjectMapper();
    private static final EventBridgeClient eventBridgeClient = EventBridgeClient.builder().build();
    private static final String EVENT_BUS_NAME = System.getenv().getOrDefault("EVENT_BUS_NAME", "default");

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

            publishOrderCreatedEvent(orderNumber, email, body, classes);

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

    private void publishOrderCreatedEvent(String orderNumber, String email, Map<String, Object> body, List<?> classes) {
        try {
            String userId = String.valueOf(body.getOrDefault("userId", ""));
            String amount = calculateOrderAmount(classes).toPlainString();

            String detailJson = mapper.writeValueAsString(Map.of(
                "orderId", orderNumber,
                "userId", userId,
                "userEmail", email,
                "amount", amount
            ));

            PutEventsRequestEntry entry = PutEventsRequestEntry.builder()
                .eventBusName(EVENT_BUS_NAME)
                .source("vegan-mundi.order-service")
                .detailType("OrderCreated")
                .detail(detailJson)
                .build();

            eventBridgeClient.putEvents(PutEventsRequest.builder().entries(entry).build());
            log.info("Published OrderCreated event for orderNumber={} to eventBus={}", orderNumber, EVENT_BUS_NAME);
        } catch (Exception ex) {
            log.warn("Order {} created but failed to publish OrderCreated event: {}", orderNumber, ex.getMessage());
        }
    }

    private BigDecimal calculateOrderAmount(List<?> classes) {
        BigDecimal total = BigDecimal.ZERO;

        for (Object item : classes) {
            if (!(item instanceof Map<?, ?> orderClass)) {
                continue;
            }

            BigDecimal price = toBigDecimal(orderClass.get("PRICE"));
            BigDecimal students = toBigDecimal(orderClass.get("NUM_STUDENTS"));
            BigDecimal discountPct = toBigDecimal(orderClass.get("DISCOUNT_PERCENTAGE"));

            BigDecimal lineTotal = price.multiply(students);
            if (discountPct.compareTo(BigDecimal.ZERO) > 0) {
                BigDecimal multiplier = BigDecimal.ONE.subtract(discountPct.divide(BigDecimal.valueOf(100)));
                lineTotal = lineTotal.multiply(multiplier);
            }
            total = total.add(lineTotal);
        }

        return total;
    }

    private BigDecimal toBigDecimal(Object value) {
        if (value == null) {
            return BigDecimal.ZERO;
        }
        try {
            return new BigDecimal(String.valueOf(value));
        } catch (NumberFormatException ex) {
            return BigDecimal.ZERO;
        }
    }
}

