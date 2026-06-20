package com.veganmundi.review.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Review endpoints — mirrors Node.js reviewRouter/reviewController exactly.
 *
 * POST /review/add
 * GET  /review/get          ?email= &classId=
 * GET  /review/get-all      ?classId=
 * GET  /review/get-class    ?classId=
 */
@RestController
@RequestMapping("/review")
@CrossOrigin(origins = "*")
public class ReviewController {

    @Autowired
    private JdbcTemplate jdbc;

    // ── POST /review/add ──────────────────────────────────────────────────────

    @PostMapping("/add")
    public ResponseEntity<?> addReview(@RequestBody Map<String, Object> body) {
        String email       = (String) body.get("email");
        Object classId     = body.get("classId");
        Object stars       = body.get("stars");
        String reviewTitle = (String) body.get("reviewTitle");
        String reviewText  = (String) body.get("reviewText");

        try {
            jdbc.update(
                "INSERT INTO REVIEW (EMAIL, CLASS_ID, STARS, REVIEW_TITLE, REVIEW_TEXT) VALUES (?, ?, ?, ?, ?)",
                email, classId, stars, reviewTitle, reviewText
            );
            return ResponseEntity.status(HttpStatus.CREATED)
                .body(Map.of("message", "Review added successfully for class " + classId));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", e.getMessage()));
        }
    }

    // ── GET /review/get ───────────────────────────────────────────────────────
    // Node.js reads from req.body; here we use query params (frontend doesn't call this endpoint)

    @GetMapping("/get")
    public ResponseEntity<?> getReview(
            @RequestParam String email,
            @RequestParam Object classId) {
        try {
            List<Map<String, Object>> result = jdbc.queryForList(
                "SELECT EMAIL, CLASS_ID, STARS, REVIEW_TEXT FROM REVIEW WHERE EMAIL = ? AND CLASS_ID = ?",
                email, classId
            );
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", e.getMessage()));
        }
    }

    // ── GET /review/get-all ───────────────────────────────────────────────────

    @GetMapping("/get-all")
    public ResponseEntity<?> getAllReviews(@RequestParam Object classId) {
        try {
            List<Map<String, Object>> result = jdbc.queryForList(
                "SELECT EMAIL, CLASS_ID, STARS, REVIEW_TEXT FROM REVIEW WHERE CLASS_ID = ?",
                classId
            );
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", e.getMessage()));
        }
    }

    // ── GET /review/get-class ─────────────────────────────────────────────────

    @GetMapping("/get-class/")
    public ResponseEntity<?> getClassReviews(@RequestParam Object classId) {
        try {
            List<Map<String, Object>> result = jdbc.queryForList(
                "SELECT STARS, REVIEW_TITLE, REVIEW_TEXT," +
                " (SELECT FIRST_NAME FROM ACCOUNT ACT WHERE REV.EMAIL = ACT.EMAIL) AS REVIEWER_NAME" +
                " FROM REVIEW REV WHERE CLASS_ID = ?",
                classId
            );
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", e.getMessage()));
        }
    }
}
