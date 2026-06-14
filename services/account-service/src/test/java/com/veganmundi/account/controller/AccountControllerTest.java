package com.veganmundi.account.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class AccountControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void testHealthEndpoint() throws Exception {
        mockMvc.perform(get("/api/account/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.service").value("account-service"))
                .andExpect(jsonPath("$.status").value("UP"));
    }

    @Test
    void testRegisterEndpoint() throws Exception {
        mockMvc.perform(get("/api/account/register"))
                .andExpect(status().isOk());
    }

    @Test
    void testLoginEndpoint() throws Exception {
        mockMvc.perform(get("/api/account/login"))
                .andExpect(status().isOk());
    }
}
