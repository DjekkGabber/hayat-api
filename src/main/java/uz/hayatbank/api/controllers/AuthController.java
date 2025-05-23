package uz.hayatbank.api.controllers;

import org.apache.ibatis.session.SqlSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import uz.hayatbank.api.bean.UserBean;
import uz.hayatbank.api.db.DBConfig;
import uz.hayatbank.api.transport.argument.LoginViaOtpArgument;
import uz.hayatbank.api.transport.argument.RegistrationArgument;
import uz.hayatbank.api.transport.argument.TokenArgument;
import uz.hayatbank.api.transport.result.CheckPhoneResult;
import uz.hayatbank.api.transport.result.TokenResult;
import uz.hayatbank.api.utils.Constants;
import uz.hayatbank.api.utils.JwtUtil;
import uz.hayatbank.api.utils.ReturnCodes;
import uz.hayatbank.api.utils.Utils;

import javax.crypto.SecretKey;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RequestMapping("/api/auth")
@RestController
public class AuthController extends BaseController {
    public static final Logger _logger = LoggerFactory.getLogger(AuthController.class);

    @GetMapping("/check")
    private ResponseEntity<?> checkPhone(@RequestParam(value = "phone") String phoneNumber) {
        CheckPhoneResult result = new CheckPhoneResult();

        if (phoneNumber == null || phoneNumber.trim().isEmpty()) {
            result.setCode(ReturnCodes.CONST_PHONE_IS_EMPTY);
            result.setMessage("Telefon raqam kiritilmagan");
            return ResponseEntity.badRequest().body(result);
        }

        if (!Utils.isPhoneNumber(phoneNumber)) {
            result.setCode(ReturnCodes.CONST_INVALID_PHONE_NUMBER);
            result.setMessage("Telefon raqam xato kiritilgan. Iltimos, tekshirib qayta kiriting. Telefon raqam operator kodi (2 ta raqam) va abonent raqami (7 ta raqam)dan iborat bo`lishi kerak (Misol: 991234567)");
            return ResponseEntity.badRequest().body(result);
        }

        Integer checkResult = checkPhoneNumber(phoneNumber);

        if (checkResult != 1) {
            result.setCode(ReturnCodes.CONST_INVALID_PHONE_NUMBER);
            result.setMessage("Telefon raqam xato kiritilgan. Iltimos, tekshirib qayta kiriting. Telefon raqam operator kodi (2 ta raqam) va abonent raqami (7 ta raqam)dan iborat bo`lishi kerak (Misol: 991234567)");
            return ResponseEntity.badRequest().body(result);
        }

        Map<String, Object> map = new HashMap<>();
        map.put("phone_number", phoneNumber);
        map.put("user_statuses_id", Constants.USER_STATUSES_ACTIVE);

        List<UserBean> users = getUsersList(map);

        if (users.size() > 1) {
            result.setCode(ReturnCodes.CONST_USER_NOT_FOUND);
            result.setMessage("Foydalanuvchi topilmadi");
            return ResponseEntity.badRequest().body(result);
        }

        try (SqlSession sqlSession = DBConfig.getSqlSession()) {

            Map<String, Object> otpMap = new HashMap<>();
            otpMap.put("p_phone", users.isEmpty() ? phoneNumber : users.get(0).getPhone());
            otpMap.put("p_session_id", null);
            otpMap.put("p_result", null);
            otpMap.put("p_result_msg", null);

            sqlSession.update("create_otp_session", otpMap);

            Integer otpResult = (Integer) otpMap.get("p_result");

            if (otpResult != 0) {
                result.setCode(otpResult);
                result.setMessage("" + otpMap.get("p_result_msg"));
                return ResponseEntity.badRequest().body(result);
            }

            result.setNeed_register(users.isEmpty() ? 1 : 0);
            result.setOtp_session("" + otpMap.get("p_session_id"));

            result.setCode(ReturnCodes.CONST_SUCCESS);
            result.setMessage("Success");

        } catch (Exception e) {
            _logger.error(e.getMessage(), e);
            result.setCode(ReturnCodes.CONST_DB_ERROR);
            result.setMessage("Ma`lumotlar bazasiga ulanib bo`lmadi. Iltimos, qaytadan urinib ko`ring");
            return ResponseEntity.badRequest().body(result);
        }

        return ResponseEntity.ok(result);
    }

    @PostMapping("/login")
    private ResponseEntity<?> loginViaOtp(@RequestBody LoginViaOtpArgument argument) {
        TokenResult result = new TokenResult();

        if (argument.getPhone() == null || argument.getPhone().trim().isEmpty()) {
            result.setCode(ReturnCodes.CONST_PHONE_IS_EMPTY);
            result.setMessage("Telefon raqam kiritilmagan");
            return ResponseEntity.badRequest().body(result);
        }

        if (!Utils.isPhoneNumber(argument.getPhone())) {
            result.setCode(ReturnCodes.CONST_INVALID_PHONE_NUMBER);
            result.setMessage("Telefon raqam xato kiritilgan. Iltimos, tekshirib qayta kiriting. Telefon raqam operator kodi (2 ta raqam) va abonent raqami (7 ta raqam)dan iborat bo`lishi kerak (Misol: 991234567)");
            return ResponseEntity.badRequest().body(result);
        }

        if (argument.getOtp_session() == null || argument.getOtp_session().trim().isEmpty()) {
            result.setCode(ReturnCodes.CONST_REQUIRED_FIELD_EMPTY);
            result.setMessage("Kerakli maydonlardan biri kiritilmagan (OTP_SESSION)");
            return ResponseEntity.badRequest().body(result);
        }

        if (argument.getOtp_code() == null || argument.getOtp_code().trim().isEmpty()) {
            result.setCode(ReturnCodes.CONST_REQUIRED_FIELD_EMPTY);
            result.setMessage("Kerakli maydonlardan biri kiritilmagan (OTP_CODE)");
            return ResponseEntity.badRequest().body(result);
        }

        Integer checkResult = checkPhoneNumber(argument.getPhone());

        if (checkResult != 1) {
            result.setCode(ReturnCodes.CONST_INVALID_PHONE_NUMBER);
            result.setMessage("Telefon raqam xato kiritilgan. Iltimos, tekshirib qayta kiriting. Telefon raqam operator kodi (2 ta raqam) va abonent raqami (7 ta raqam)dan iborat bo`lishi kerak (Misol: 991234567)");
            return ResponseEntity.badRequest().body(result);
        }

        Map<String, Object> map = new HashMap<>();
        map.put("phone_number", argument.getPhone());
        map.put("user_statuses_id", Constants.USER_STATUSES_ACTIVE);

        List<UserBean> users = getUsersList(map);

        if (users.size() != 1) {
            result.setCode(ReturnCodes.CONST_USER_NOT_FOUND);
            result.setMessage("Foydalanuvchi topilmadi");
            return ResponseEntity.badRequest().body(result);
        }

        UserBean user = users.get(0);

        if (!user.getPhone().equalsIgnoreCase(argument.getPhone())) {
            result.setCode(ReturnCodes.CONST_USER_NOT_FOUND);
            result.setMessage("Foydalanuvchi topilmadi");
            return ResponseEntity.badRequest().body(result);
        }

        SqlSession sqlSession = DBConfig.getSqlSessionTransaction();

        try {

            Map<String, Object> otpMap = new HashMap<>();
            otpMap.put("p_session_id", argument.getOtp_session());
            otpMap.put("p_code", argument.getOtp_code());
            otpMap.put("p_try_cnt", null);
            otpMap.put("p_result", null);
            otpMap.put("p_result_msg", null);

            sqlSession.update("check_otp_session", otpMap);

            Integer otpResult = (Integer) otpMap.get("p_result");

            if (otpResult != 0) {
                result.setCode(otpResult);
                result.setMessage("" + otpMap.get("p_result_msg"));
                sqlSession.rollback();
                return ResponseEntity.badRequest().body(result);
            }

            SecretKey key = JwtUtil.getKey();
            String refreshToken = JwtUtil.getRefreshToken(key);
            String authToken = JwtUtil.getAuthToken(key, user.getFio());

            Map<String, Object> tokenMap = new HashMap<>();
            tokenMap.put("p_users_id", user.getId());
            tokenMap.put("p_auth_token", authToken);
            tokenMap.put("p_refresh_token", refreshToken);
            tokenMap.put("p_result", null);
            tokenMap.put("p_result_msg", null);

            sqlSession.update("add_token", tokenMap);

            Integer tokenResult = (Integer) tokenMap.get("p_result");

            if (tokenResult != 0) {
                result.setCode(tokenResult);
                result.setMessage("" + tokenMap.get("p_result_msg"));
                sqlSession.rollback();
                return ResponseEntity.badRequest().body(result);
            }

            result.setAuth_token(authToken);
            result.setRefresh_token(refreshToken);

            result.setCode(ReturnCodes.CONST_SUCCESS);
            result.setMessage("Success");

            sqlSession.commit();
        } catch (Exception e) {
            _logger.error(e.getMessage(), e);
            result.setCode(ReturnCodes.CONST_DB_ERROR);
            result.setMessage("Ma`lumotlar bazasiga ulanib bo`lmadi. Iltimos, qaytadan urinib ko`ring");
            sqlSession.rollback();
            return ResponseEntity.badRequest().body(result);
        }

        return ResponseEntity.ok(result);
    }

    @PostMapping("/refresh-token")
    private ResponseEntity<?> refreshToken(@RequestBody TokenArgument argument) {
        TokenResult result = new TokenResult();

        if (argument.getRefresh_token() == null || argument.getRefresh_token().trim().isEmpty()) {
            result.setCode(ReturnCodes.CONST_REQUIRED_FIELD_EMPTY);
            result.setMessage("Kerakli maydonlardan biri kiritilmagan (REFRESH_TOKEN)");
            return ResponseEntity.badRequest().body(result);
        }

        UserBean user = getUserByRefreshToken(argument.getRefresh_token());

        if (user == null) {
            result.setCode(ReturnCodes.CONST_USER_NOT_FOUND);
            result.setMessage("Foydalanuvchi topilmadi");
            return ResponseEntity.status(HttpStatusCode.valueOf(HttpStatus.UNAUTHORIZED.value())).body(result);
        }

        try (SqlSession sqlSession = DBConfig.getSqlSession()) {
            SecretKey key = JwtUtil.getKey();
            String refreshToken = JwtUtil.getRefreshToken(key);
            String authToken = JwtUtil.getAuthToken(key, user.getFio());

            Map<String, Object> tokenMap = new HashMap<>();
            tokenMap.put("p_users_id", user.getId());
            tokenMap.put("p_auth_token", authToken);
            tokenMap.put("p_refresh_token", refreshToken);
            tokenMap.put("p_result", null);
            tokenMap.put("p_result_msg", null);

            sqlSession.update("add_token", tokenMap);

            Integer tokenResult = (Integer) tokenMap.get("p_result");

            if (tokenResult != 0) {
                result.setCode(tokenResult);
                result.setMessage("" + tokenMap.get("p_result_msg"));
                return ResponseEntity.badRequest().body(result);
            }

            result.setAuth_token(authToken);
            result.setRefresh_token(refreshToken);

            result.setCode(ReturnCodes.CONST_SUCCESS);
            result.setMessage("Success");

        } catch (Exception e) {
            _logger.error(e.getMessage(), e);
            result.setCode(ReturnCodes.CONST_DB_ERROR);
            result.setMessage("Ma`lumotlar bazasiga ulanib bo`lmadi. Iltimos, qaytadan urinib ko`ring");
            return ResponseEntity.badRequest().body(result);
        }

        return ResponseEntity.ok(result);
    }

    @PostMapping("/registration")
    private ResponseEntity<?> registration(@RequestBody RegistrationArgument argument) {
        TokenResult result = new TokenResult();

        if (argument.getPhone() == null || argument.getPhone().trim().isEmpty()) {
            result.setCode(ReturnCodes.CONST_PHONE_IS_EMPTY);
            result.setMessage("Telefon raqam kiritilmagan");
            return ResponseEntity.badRequest().body(result);
        }

        if (!Utils.isPhoneNumber(argument.getPhone())) {
            result.setCode(ReturnCodes.CONST_INVALID_PHONE_NUMBER);
            result.setMessage("Telefon raqam xato kiritilgan. Iltimos, tekshirib qayta kiriting. Telefon raqam operator kodi (2 ta raqam) va abonent raqami (7 ta raqam)dan iborat bo`lishi kerak (Misol: 991234567)");
            return ResponseEntity.badRequest().body(result);
        }

        if (argument.getFio() == null || argument.getFio().trim().isEmpty()) {
            result.setCode(ReturnCodes.CONST_FIO_IS_EMPTY);
            result.setMessage("Foydalanuvchi F.I.Sh. si kiritilmagan");
            return ResponseEntity.badRequest().body(result);
        }

        if (argument.getFio().length() < 3) {
            result.setCode(ReturnCodes.CONST_FIO_IS_EMPTY);
            result.setMessage("Foydalanuvchi F.I.Sh. si 4 ta belgidan kam bo`lmasligi kerak");
            return ResponseEntity.badRequest().body(result);
        }

        if (argument.getEmail() != null && !argument.getEmail().trim().isEmpty()) {
            if (!Utils.isEmail(argument.getEmail())) {
                result.setCode(ReturnCodes.CONST_INVALID_EMAIL);
                result.setMessage("E-Mail xato kiritilgan. Iltimos, tekshirib qayta kiriting");
                return ResponseEntity.badRequest().body(result);
            }
        }

        if (argument.getOtp_session() == null || argument.getOtp_session().trim().isEmpty()) {
            result.setCode(ReturnCodes.CONST_REQUIRED_FIELD_EMPTY);
            result.setMessage("Kerakli maydonlardan biri kiritilmagan (OTP_SESSION)");
            return ResponseEntity.badRequest().body(result);
        }

        if (argument.getOtp_code() == null || argument.getOtp_code().trim().isEmpty()) {
            result.setCode(ReturnCodes.CONST_REQUIRED_FIELD_EMPTY);
            result.setMessage("Kerakli maydonlardan biri kiritilmagan (OTP_CODE)");
            return ResponseEntity.badRequest().body(result);
        }

        Integer checkResult = checkPhoneNumber(argument.getPhone());

        if (checkResult != 1) {
            result.setCode(ReturnCodes.CONST_INVALID_PHONE_NUMBER);
            result.setMessage("Telefon raqam xato kiritilgan. Iltimos, tekshirib qayta kiriting. Telefon raqam operator kodi (2 ta raqam) va abonent raqami (7 ta raqam)dan iborat bo`lishi kerak (Misol: 991234567)");
            return ResponseEntity.badRequest().body(result);
        }

        Map<String, Object> map = new HashMap<>();
        map.put("phone_number", argument.getPhone());
        map.put("user_statuses_id", Constants.USER_STATUSES_ACTIVE);

        List<UserBean> users = getUsersList(map);

        if (users.size() == 1) {
            result.setCode(ReturnCodes.CONST_PHONE_EXISTS);
            result.setMessage("Ushbu telefon raqami bilan ro`yxatdan o`tgansiz. Iltimos, boshqa telefon raqamini kiriting");
            return ResponseEntity.badRequest().body(result);
        }

        try (SqlSession sqlSession = DBConfig.getSqlSession()) {

            SecretKey key = JwtUtil.getKey();
            String refreshToken = JwtUtil.getRefreshToken(key);
            String authToken = JwtUtil.getAuthToken(key, argument.getFio());

            Map<String, Object> userMap = new HashMap<>();
            userMap.put("p_fio", argument.getFio());
            userMap.put("p_phone", argument.getPhone());
            userMap.put("p_email", argument.getEmail());
            userMap.put("p_auth_token", authToken);
            userMap.put("p_refresh_token", refreshToken);
            userMap.put("p_session_id", argument.getOtp_session());
            userMap.put("p_otp_code", argument.getOtp_code());
            userMap.put("p_result", null);
            userMap.put("p_result_msg", null);

            sqlSession.update("create_user", userMap);

            Integer userResult = (Integer) userMap.get("p_result");

            if (userResult != 0) {
                result.setCode(userResult);
                result.setMessage("" + userMap.get("p_result_msg"));
                return ResponseEntity.badRequest().body(result);
            }

            result.setAuth_token(authToken);
            result.setRefresh_token(refreshToken);

            result.setCode(ReturnCodes.CONST_SUCCESS);
            result.setMessage("Success");

        } catch (Exception e) {
            _logger.error(e.getMessage(), e);
            result.setCode(ReturnCodes.CONST_DB_ERROR);
            result.setMessage("Ma`lumotlar bazasiga ulanib bo`lmadi. Iltimos, qaytadan urinib ko`ring");
            return ResponseEntity.badRequest().body(result);
        }

        return ResponseEntity.ok(result);
    }
}
