package com.veganmundi.classes.controller;

import com.veganmundi.shared.security.JwtTokenProvider;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Class endpoints — mirrors Node.js classRouter/classController exactly.
 *
 * GET  /classes/categories
 * GET  /classes/free
 * GET  /classes/category/{category}   ?email=
 * GET  /classes/filter/{keyword}      ?email=
 * GET  /classes/user                  ?email= &deliveryMethod= &pageNumber=   (JWT required)
 * POST /classes/update-date
 */
@RestController
@RequestMapping("/classes")
public class ClassController {

    @Autowired
    private JdbcTemplate jdbc;

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    @Value("${app.page-size:12}")
    private int pageSize;

    @GetMapping("/categories")
    public ResponseEntity<?> getCategories() {
        try {
            List<Map<String, Object>> result = jdbc.queryForList(
                "SELECT * FROM CLASS_CATEGORY WHERE CATEGORY_ID IN (2, 3, 4) ORDER BY DISPLAY_ORDER"
            );
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/free")
    public ResponseEntity<?> getFreeClasses() {
        try {
            List<Map<String, Object>> result = jdbc.queryForList(
                "SELECT RCP.RECIPE_ID, RCP.TITLE, RCP.DESCRIPTION, RCP.PHOTO, RCP.VIDEO, RCP.PUBLISH_DATE, RCP.DISPLAY_ORDER" +
                " FROM CLASS CLS" +
                "  INNER JOIN CLASS_RECIPE CLR ON CLS.CLASS_ID = CLR.CLASS_ID AND CLS.CATEGORY_ID = 1" +
                "  INNER JOIN RECIPE RCP ON CLR.RECIPE_ID = RCP.RECIPE_ID" +
                "  ORDER BY DISPLAY_ORDER"
            );
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/category/{category}")
    public ResponseEntity<?> getClassesPerCategory(
            @PathVariable String category,
            @RequestParam(required = false) String email) {
        try {
            String sql =
                "SELECT DISTINCT CAT.TITLE AS CATEGORY_TITLE, CLS.CLASS_ID, CLS.CATEGORY_ID, CLS.TITLE, CLS.DESCRIPTION, CLS.PHOTO," +
                " (SELECT TRUNCATE(AVG(STARS),1) FROM REVIEW REV WHERE REV.CLASS_ID = CLS.CLASS_ID GROUP BY CLASS_ID) AS AVERAGE_STARS," +
                " (SELECT GROUP_CONCAT(TITLE SEPARATOR '|') FROM RECIPE R INNER JOIN CLASS_RECIPE C ON R.RECIPE_ID = C.RECIPE_ID" +
                "   AND C.CLASS_ID = CLS.CLASS_ID AND (SELECT COUNT(TITLE) FROM RECIPE R INNER JOIN CLASS_RECIPE C ON R.RECIPE_ID = C.RECIPE_ID AND C.CLASS_ID = CLS.CLASS_ID) > 1) CLASSES_LIST" +
                " FROM CLASS_CATEGORY CAT INNER JOIN CLASS CLS ON CAT.CATEGORY_ID = CLS.CATEGORY_ID";

            List<Object> params = new ArrayList<>();
            if (email != null) {
                sql += " AND CLS.CLASS_ID NOT IN (SELECT CLASS_ID FROM ORDER_CLASS OCL WHERE EMAIL = ?)";
                params.add(email);
            }
            sql += " AND UPPER(CAT.CATEGORY_ID) = ?" +
                   " INNER JOIN CLASS_RECIPE CLR ON CLS.CLASS_ID = CLR.CLASS_ID" +
                   " INNER JOIN RECIPE RCP ON CLR.RECIPE_ID = RCP.RECIPE_ID";
            params.add(category);

            List<Map<String, Object>> result = jdbc.queryForList(sql, params.toArray());

            String categoryTitle = result.isEmpty() ? null : (String) result.get(0).get("CATEGORY_TITLE");
            return ResponseEntity.ok(Map.of("categoryTitle", categoryTitle != null ? categoryTitle : "", "classes", result));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/filter/{keyword}")
    public ResponseEntity<?> getClassesPerKeyword(
            @PathVariable String keyword,
            @RequestParam(required = false) String email) {
        try {
            String likeKeyword = "%" + keyword + "%";
            String sql =
                "SELECT DISTINCT CLS.CATEGORY_ID, CLS.CLASS_ID, CLS.TITLE, CLS.DESCRIPTION, CLS.PHOTO," +
                " (SELECT TRUNCATE(AVG(STARS),1) FROM REVIEW REV WHERE REV.CLASS_ID = CLS.CLASS_ID GROUP BY CLASS_ID) AS AVERAGE_STARS," +
                " (SELECT GROUP_CONCAT(TITLE SEPARATOR '|') FROM RECIPE R INNER JOIN CLASS_RECIPE C ON R.RECIPE_ID = C.RECIPE_ID" +
                "   AND C.CLASS_ID = CLS.CLASS_ID AND (SELECT COUNT(TITLE) FROM RECIPE R INNER JOIN CLASS_RECIPE C ON R.RECIPE_ID = C.RECIPE_ID AND C.CLASS_ID = CLS.CLASS_ID) > 1) CLASSES_LIST" +
                " FROM CLASS CLS INNER JOIN CLASS_RECIPE CLR ON CLS.CLASS_ID = CLR.CLASS_ID";

            List<Object> params = new ArrayList<>();
            if (email != null) {
                sql += " AND CLS.CLASS_ID NOT IN (SELECT CLASS_ID FROM ORDER_CLASS OCL WHERE EMAIL = ?)";
                params.add(email);
            }
            sql += " INNER JOIN RECIPE RCP ON CLR.RECIPE_ID = RCP.RECIPE_ID AND RCP.KEYWORD LIKE ?";
            params.add(likeKeyword);

            List<Map<String, Object>> result = jdbc.queryForList(sql, params.toArray());
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/user")
    public ResponseEntity<?> getUserClasses(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestParam String email,
            @RequestParam(defaultValue = "0") int pageNumber,
            @RequestParam String deliveryMethod) {

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(Map.of("error", "Authentication token missing"));
        }
        String token = authHeader.substring(7);
        if (!jwtTokenProvider.validateToken(token)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(Map.of("error", "Invalid or expired token"));
        }

        try {
            int offset = pageNumber * pageSize;
            String sql =
                "SELECT DISTINCT CLS.CATEGORY_ID, CAT.TITLE AS CATEGORY_TITLE," +
                " OCL.DELIVERY_METHOD_ID, DME.TITLE, OCL.CLASS_DATE," +
                " CLS.CLASS_ID, CLS.TITLE, CLS.DESCRIPTION, CLS.PHOTO," +
                " (SELECT CONCAT('[', GROUP_CONCAT(CONCAT('{\"TITLE\":\"', R.TITLE, '\",\"PHOTO\":\"', R.PHOTO, '\"}') SEPARATOR ','), ']')" +
                "   FROM RECIPE R INNER JOIN CLASS_RECIPE C ON R.RECIPE_ID = C.RECIPE_ID AND C.CLASS_ID = CLS.CLASS_ID" +
                "   WHERE C.CLASS_ID = CLS.CLASS_ID) AS CLASSES_LIST," +
                " REV.STARS, REV.REVIEW_TITLE, REV.REVIEW_TEXT," +
                " COUNT(*) OVER() AS TOTAL_RECORDS" +
                " FROM CLASS_CATEGORY CAT" +
                " INNER JOIN CLASS CLS ON CAT.CATEGORY_ID = CLS.CATEGORY_ID" +
                "   AND CLS.CLASS_ID IN (SELECT CLASS_ID FROM ORDER_CLASS OCL WHERE EMAIL = ?)" +
                " INNER JOIN ORDER_CLASS OCL ON CLS.CLASS_ID = OCL.CLASS_ID AND OCL.EMAIL = ?" +
                " INNER JOIN DELIVERY_METHOD DME ON OCL.DELIVERY_METHOD_ID = DME.ID AND DME.ID = ?" +
                " LEFT JOIN REVIEW REV ON CLS.CLASS_ID = REV.CLASS_ID AND REV.EMAIL = ?" +
                " LIMIT ? OFFSET ?";

            List<Map<String, Object>> result = jdbc.queryForList(
                sql, email, email, deliveryMethod, email, pageSize, offset
            );

            long totalRecords = result.isEmpty() ? 0 : ((Number) result.get(0).get("TOTAL_RECORDS")).longValue();
            long totalPages   = (long) Math.ceil((double) totalRecords / pageSize);

            return ResponseEntity.ok(Map.of("data", result, "totalPages", totalPages));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/update-date")
    public ResponseEntity<?> updateClassDate(@RequestBody Map<String, Object> body) {
        try {
            Object date    = body.get("date");
            String email   = (String) body.get("email");
            Object classId = body.get("classId");

            jdbc.update(
                "UPDATE ORDER_CLASS SET CLASS_DATE = ? WHERE EMAIL = ? AND CLASS_ID = ?",
                date, email, classId
            );
            return ResponseEntity.ok(Map.of("message", "Class date updated"));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", e.getMessage()));
        }
    }
}
