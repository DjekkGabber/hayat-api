package uz.hayatbank.api.utils;

import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.io.Encoders;
import io.jsonwebtoken.security.Keys;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import javax.crypto.SecretKey;
import java.util.Date;

public class JwtUtil {
    public static final Logger _logger = LogManager.getLogger(JwtUtil.class);

    public static SecretKey getKey(){
        return  Keys.secretKeyFor(SignatureAlgorithm.HS256);
    }
    public static String getRefreshToken(SecretKey key) {
            return Encoders.BASE64URL.encode(key.getEncoded());
    }
    public static String getAuthToken(SecretKey key, String username) {
        try {
            return Jwts.builder().setSubject(username).setIssuedAt(new Date()).signWith(key).compact();
            } catch (JwtException e) {
            return null;
        }
    }
}
