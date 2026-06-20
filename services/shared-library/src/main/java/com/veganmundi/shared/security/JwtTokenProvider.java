package com.veganmundi.shared.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.Date;

/**
 * JWT Token utility — compatible with Node.js jsonwebtoken (HS256, same payload shape).
 * Payload: { firstName, lastName, email, iat, exp }
 */
@Component
public class JwtTokenProvider {

    @Value("${jwt.secret}")
    private String jwtSecret;

    private SecretKey buildKey() {
        // Use SecretKeySpec directly to avoid JJWT minimum-length validation;
        // this keeps us compatible with the Node.js secret which is < 32 bytes.
        return new SecretKeySpec(jwtSecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
    }

    /**
     * Generate a token matching the Node.js jsonwebtoken payload shape.
     * Expiry: 1 hour (same as Node.js { expiresIn: '1h' }).
     */
    public String generateToken(String firstName, String lastName, String email) {
        return Jwts.builder()
                .claim("firstName", firstName)
                .claim("lastName", lastName)
                .claim("email", email)
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + 3_600_000L))
                .signWith(buildKey(), SignatureAlgorithm.HS256)
                .compact();
    }

    /**
     * Extract all claims from a token (works for tokens issued by either Node.js or Java).
     */
    public Claims getClaimsFromToken(String token) {
        return Jwts.parser()
                .verifyWith(buildKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public String getEmailFromToken(String token) {
        return (String) getClaimsFromToken(token).get("email");
    }

    public boolean validateToken(String token) {
        try {
            getClaimsFromToken(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}
