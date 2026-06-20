package com.veganmundi.gallery.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Gallery endpoints — mirrors Node.js galleryRouter/galleryController.
 * GET /gallery
 */
@RestController
public class GalleryController {

    @Autowired
    private JdbcTemplate jdbc;

    @GetMapping("/gallery")
    public ResponseEntity<?> getGallery() {
        try {
            List<Map<String, Object>> result = jdbc.queryForList("SELECT * FROM GALLERY");
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", e.getMessage()));
        }
    }
}
