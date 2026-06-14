package com.veganmundi.shared.security;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class JwtTokenProviderTest {

    private final JwtTokenProvider tokenProvider = new JwtTokenProvider();

    @Test
    void testTokenGeneration() {
        String token = tokenProvider.generateToken("user-123", "test@example.com");
        assertNotNull(token);
        assertFalse(token.isEmpty());
    }

    @Test
    void testTokenValidation() {
        String token = tokenProvider.generateToken("user-123", "test@example.com");
        assertTrue(tokenProvider.validateToken(token));
    }

    @Test
    void testTokenExtraction() {
        String userId = "user-123";
        String token = tokenProvider.generateToken(userId, "test@example.com");
        assertEquals(userId, tokenProvider.getUserIdFromToken(token));
    }

    @Test
    void testInvalidTokenValidation() {
        String invalidToken = "invalid-token-xyz";
        assertFalse(tokenProvider.validateToken(invalidToken));
    }
}
