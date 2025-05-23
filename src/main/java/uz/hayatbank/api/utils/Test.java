package uz.hayatbank.api.utils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.crypto.SecretKey;

public class Test {
    public static final Logger _logger = LoggerFactory.getLogger(Test.class);

    public static void main(String[] args) {
        SecretKey key = JwtUtil.getKey();
        String refreshToken = JwtUtil.getRefreshToken(key);
        _logger.info(refreshToken);
        String jwtToken = JwtUtil.getAuthToken(key, "Yusuf");
        _logger.info(jwtToken);

    }
}
