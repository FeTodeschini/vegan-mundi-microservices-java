package com.veganmundi.lambda;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.LambdaLogger;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SQSEvent;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import software.amazon.awssdk.services.ses.SesClient;
import software.amazon.awssdk.services.ses.model.SendEmailRequest;
import software.amazon.awssdk.services.ses.model.SendEmailResponse;

/**
 * Lambda handler for processing OrderCreated events via EventBridge.
 * Sends confirmation emails and publishes analytics.
 */
public class OrderConfirmationHandler implements RequestHandler<SQSEvent, String> {

    private static final ObjectMapper mapper = new ObjectMapper();
    private static final SesClient sesClient = SesClient.builder().build();
    private static final String SENDER_EMAIL = System.getenv("SENDER_EMAIL");
    private static final String ANALYTICS_TABLE = System.getenv("ANALYTICS_TABLE");

    @Override
    public String handleRequest(SQSEvent event, Context context) {
        LambdaLogger logger = context.getLogger();
        logger.log("Processing " + event.getRecords().size() + " events");

        for (SQSEvent.SQSMessage message : event.getRecords()) {
            try {
                JsonNode eventData = mapper.readTree(message.getBody());
                String orderId = eventData.get("orderId").asText();
                String userId = eventData.get("userId").asText();
                String userEmail = eventData.get("userEmail").asText();
                String orderAmount = eventData.get("amount").asText();

                // Send confirmation email
                sendConfirmationEmail(userEmail, orderId, orderAmount, logger);

                // Write analytics (optional)
                recordAnalytics(orderId, userId, logger);

                logger.log("Successfully processed order: " + orderId);
            } catch (Exception e) {
                logger.log("Error processing message: " + e.getMessage());
                throw new RuntimeException(e);
            }
        }

        return "Success";
    }

    private void sendConfirmationEmail(String toEmail, String orderId, String amount, LambdaLogger logger) {
        try {
            SendEmailRequest request = SendEmailRequest.builder()
                    .source(SENDER_EMAIL)
                    .destination(d -> d.toAddresses(toEmail))
                    .message(m -> m
                            .subject(s -> s.data("Order Confirmation #" + orderId))
                            .body(b -> b.html(h -> h.data(buildEmailHtml(orderId, amount))))
                    )
                    .build();

            SendEmailResponse result = sesClient.sendEmail(request);
            logger.log("Email sent with ID: " + result.messageId());
        } catch (Exception e) {
            logger.log("Failed to send email: " + e.getMessage());
            throw new RuntimeException(e);
        }
    }

    private void recordAnalytics(String orderId, String userId, LambdaLogger logger) {
        // TODO: Write to DynamoDB analytics table (optional)
        logger.log("Recording analytics for order: " + orderId);
    }

    private String buildEmailHtml(String orderId, String amount) {
        return "<html>" +
                "<body>" +
                "<h1>Order Confirmation</h1>" +
                "<p>Thank you for your order!</p>" +
                "<p>Order ID: " + orderId + "</p>" +
                "<p>Amount: $" + amount + "</p>" +
                "<p>You will receive your items soon.</p>" +
                "</body>" +
                "</html>";
    }
}
