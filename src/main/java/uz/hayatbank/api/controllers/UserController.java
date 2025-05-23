package uz.hayatbank.api.controllers;

import org.apache.ibatis.session.RowBounds;
import org.apache.ibatis.session.SqlSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import uz.hayatbank.api.bean.UserBean;
import uz.hayatbank.api.db.DBConfig;
import uz.hayatbank.api.transport.GenericPagingArgument;
import uz.hayatbank.api.transport.argument.ChangeSelfInfoArgument;
import uz.hayatbank.api.transport.result.SelfInfoResult;
import uz.hayatbank.api.transport.result.UsersInfoResult;
import uz.hayatbank.api.utils.Constants;
import uz.hayatbank.api.utils.ReturnCodes;
import uz.hayatbank.api.utils.Utils;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RequestMapping("/api/user")
@RestController
public class UserController extends BaseController {

    public static final Logger _logger = LoggerFactory.getLogger(UserController.class);

    @GetMapping("/self")
    private ResponseEntity<?> getSelfUserInfo(@RequestHeader Map<String, String> headers) {
        SelfInfoResult result = new SelfInfoResult();

        UserBean user = getUserByAccess(headers);

        if (user == null) {
            result.setCode(ReturnCodes.CONST_USER_NOT_FOUND);
            result.setMessage("Foydalanuvchi topilmadi");
            return ResponseEntity.status(HttpStatusCode.valueOf(HttpStatus.UNAUTHORIZED.value())).body(result);
        }

        result.setSelf(user);
        result.setCode(ReturnCodes.CONST_SUCCESS);
        result.setMessage("Success");

        return ResponseEntity.ok(result);
    }

    @PostMapping("/all")
    private ResponseEntity<?> getAllUsers(@RequestHeader Map<String, String> headers, @RequestBody GenericPagingArgument argument) {
        UsersInfoResult result = new UsersInfoResult();

        UserBean user = getUserByAccess(headers);

        if (user == null) {
            result.setCode(ReturnCodes.CONST_USER_NOT_FOUND);
            result.setMessage("Foydalanuvchi topilmadi");
            return ResponseEntity.status(HttpStatusCode.valueOf(HttpStatus.UNAUTHORIZED.value())).body(result);
        }

        try (SqlSession sqlSession = DBConfig.getSqlSession()) {

            int currentPage = argument.getPage() != null ? argument.getPage() : 1;
            int pageSize = argument.getPer_page() != null ? argument.getPer_page() : 20;

            if (pageSize > 50) {
                pageSize = 50;
            }

            RowBounds rowbounds = new RowBounds((currentPage - 1) * pageSize, pageSize);

            Map<String, Object> map = new HashMap<>();
            map.put("user_statuses_id", Constants.USER_STATUSES_ACTIVE);

            Integer totalRows = sqlSession.selectOne("selectUsersCnt", map);
            List<UserBean> users = sqlSession.selectList("selectUsers", map, rowbounds);

            result.setTotal(totalRows == null ? 0 : totalRows);
            result.setCurrent(currentPage);
            result.setPages(Utils.calculatePagesCount(pageSize, totalRows));

            result.setUsers(users);
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

    @PostMapping("/self/update")
    private ResponseEntity<?> changeSelfInfo(@RequestHeader Map<String, String> headers, @RequestBody ChangeSelfInfoArgument argument) {
        SelfInfoResult result = new SelfInfoResult();

        UserBean user = getUserByAccess(headers);

        if (user == null) {
            result.setCode(ReturnCodes.CONST_USER_NOT_FOUND);
            result.setMessage("Foydalanuvchi topilmadi");
            return ResponseEntity.status(HttpStatusCode.valueOf(HttpStatus.UNAUTHORIZED.value())).body(result);
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

        try (SqlSession sqlSession = DBConfig.getSqlSession()) {

            Map<String, Object> userMap = new HashMap<>();
            userMap.put("p_users_id", user.getId());
            userMap.put("p_fio", argument.getFio());
            userMap.put("p_email", argument.getEmail());
            userMap.put("p_result", null);
            userMap.put("p_result_msg", null);

            sqlSession.update("update_user", userMap);

            Integer userResult = (Integer) userMap.get("p_result");

            if (userResult != 0) {
                result.setCode(userResult);
                result.setMessage("" + userMap.get("p_result_msg"));
                return ResponseEntity.badRequest().body(result);
            }

            user = getUserById(user.getId());

            result.setSelf(user);
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
