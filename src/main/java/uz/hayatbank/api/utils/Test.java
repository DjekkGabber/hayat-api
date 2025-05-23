package uz.hayatbank.api.utils;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import javax.crypto.SecretKey;

public class Test {
    public static final Logger _logger = LogManager.getLogger(Test.class);

    public static void main(String[] args) {
        SecretKey key = JwtUtil.getKey();
        String refreshToken = JwtUtil.getRefreshToken(key);
        _logger.info(refreshToken);
        String jwtToken = JwtUtil.getAuthToken(key, "Yusuf");
        _logger.info(jwtToken);

    }
}
