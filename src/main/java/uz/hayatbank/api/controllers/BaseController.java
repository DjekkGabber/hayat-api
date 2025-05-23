package uz.hayatbank.api.controllers;

import org.apache.ibatis.session.SqlSession;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.web.bind.annotation.RestController;
import uz.hayatbank.api.bean.UserBean;
import uz.hayatbank.api.db.DBConfig;
import uz.hayatbank.api.utils.Constants;
import uz.hayatbank.api.utils.Utils;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
public class BaseController {
    public static final Logger _logger = LogManager.getLogger(BaseController.class);

    protected Integer checkPhoneNumber(String phoneNumber) {
        try (SqlSession sqlSession = DBConfig.getSqlSession()) {
            Map<String, Object> map = new HashMap<>();
            map.put("phone_number", phoneNumber);

            return sqlSession.selectOne("checkPhoneNumber", map);
        } catch (Exception e) {
            _logger.error(e.getMessage(), e);
        }
        return 0;
    }

    protected List<UserBean> getUsersList(Map<String, Object> map) {
        try (SqlSession sqlSession = DBConfig.getSqlSession()) {
            return sqlSession.selectList("selectUsers", map);
        } catch (Exception e) {
            _logger.error(e.getMessage(), e);
        }
        return new ArrayList<>();
    }

    protected UserBean getUserByRefreshToken(String refreshToken) {

        try (SqlSession sqlSession = DBConfig.getSqlSession()) {

            Map<String, Object> map = new HashMap<>();
            map.put("p_refresh_token", refreshToken);
            map.put("p_invoke", 1);
            map.put("p_users_id", null);

            sqlSession.update("check_user_by_refresh_token", map);

            Integer userId = (Integer) map.get("p_users_id");

            if (userId == null) {
                return null;
            }

            Map<String, Object> userMap = new HashMap<>();
            userMap.put("user_statuses_id", Constants.USER_STATUSES_ACTIVE);
            userMap.put("id", userId);

            List<UserBean> users = getUsersList(userMap);

            if (users.size() != 1) {
                return null;
            }

            return users.get(0);
        } catch (Exception e) {
            _logger.error(e.getMessage(), e);
        }
        return null;
    }

    protected UserBean getUserByAccess(String accessToken) {

        try (SqlSession sqlSession = DBConfig.getSqlSession()) {

            Map<String, Object> map = new HashMap<>();
            map.put("p_auth_token", accessToken);
            map.put("p_users_id", null);

            sqlSession.update("check_by_auth_token", map);

            Integer userId = (Integer) map.get("p_users_id");

            if (userId == null) {
                return null;
            }

            Map<String, Object> userMap = new HashMap<>();
            userMap.put("user_statuses_id", Constants.USER_STATUSES_ACTIVE);
            userMap.put("id", userId);

            List<UserBean> users = getUsersList(userMap);

            if (users.size() != 1) {
                return null;
            }

            return users.get(0);
        } catch (Exception e) {
            _logger.error(e.getMessage(), e);
        }
        return null;
    }

    protected UserBean getUserByAccess(Map<String, String> headers) {

        String authToken = Utils.getAuthTokenFromHeader(headers);

        if (authToken == null || authToken.trim().isEmpty()) {
            return null;
        }

        return getUserByAccess(authToken);
    }

    protected UserBean getUserById(Integer userId) {
        if (userId == null) {
            return null;
        }

        try (SqlSession sqlSession = DBConfig.getSqlSession()) {

            Map<String, Object> userMap = new HashMap<>();
            userMap.put("user_statuses_id", Constants.USER_STATUSES_ACTIVE);
            userMap.put("id", userId);

            List<UserBean> users = getUsersList(userMap);

            if (users.size() != 1) {
                return null;
            }

            return users.get(0);
        } catch (Exception e) {
            _logger.error(e.getMessage(), e);
        }
        return null;
    }
}
