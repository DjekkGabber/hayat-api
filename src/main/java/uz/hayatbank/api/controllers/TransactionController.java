package uz.hayatbank.api.controllers;

import org.apache.ibatis.session.RowBounds;
import org.apache.ibatis.session.SqlSession;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import uz.hayatbank.api.bean.UserBean;
import uz.hayatbank.api.bean.UserTransactionBean;
import uz.hayatbank.api.db.DBConfig;
import uz.hayatbank.api.transport.GenericPagingArgument;
import uz.hayatbank.api.transport.GenericResult;
import uz.hayatbank.api.transport.argument.BeforePerformTransactionArgument;
import uz.hayatbank.api.transport.argument.PerformTransactionArgument;
import uz.hayatbank.api.transport.argument.TransactionsArgument;
import uz.hayatbank.api.transport.result.BeforePerformTransactionResult;
import uz.hayatbank.api.transport.result.TransactionsResult;
import uz.hayatbank.api.utils.ReturnCodes;
import uz.hayatbank.api.utils.Utils;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RequestMapping("/api/transaction")
@RestController
public class TransactionController extends BaseController {
    public static final Logger _logger = LogManager.getLogger(TransactionController.class);

    @PostMapping("/self")
    private ResponseEntity<?> getSelfTransactionsList(@RequestHeader Map<String, String> headers, @RequestBody GenericPagingArgument argument) {
        TransactionsResult result = new TransactionsResult();

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
            map.put("users_id", user.getId());

            Integer totalRows = sqlSession.selectOne("selectTransactionsCnt", map);
            List<UserTransactionBean> transactions = sqlSession.selectList("selectTransactions", map, rowbounds);

            result.setTotal(totalRows == null ? 0 : totalRows);
            result.setCurrent(currentPage);
            result.setPages(Utils.calculatePagesCount(pageSize, totalRows));

            result.setTransactions(transactions);
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

    @PostMapping("/list")
    private ResponseEntity<?> getTransactionsList(@RequestHeader Map<String, String> headers, @RequestBody TransactionsArgument argument) {
        TransactionsResult result = new TransactionsResult();

        UserBean user = getUserByAccess(headers);

        if (user == null) {
            result.setCode(ReturnCodes.CONST_USER_NOT_FOUND);
            result.setMessage("Foydalanuvchi topilmadi");
            return ResponseEntity.status(HttpStatusCode.valueOf(HttpStatus.UNAUTHORIZED.value())).body(result);
        }

        if (argument.getUser_phone() != null && !argument.getUser_phone().trim().isEmpty()) {
            if (!Utils.isPhoneNumber(argument.getUser_phone())) {
                result.setCode(ReturnCodes.CONST_INVALID_PHONE_NUMBER);
                result.setMessage("Not valid phone number");
                return ResponseEntity.badRequest().body(result);
            }
        }

        SimpleDateFormat sdf = new SimpleDateFormat("dd.MM.yyyy");
        Date dateFrom = null, dateTo = null;

        if (argument.getDate_from() != null && !argument.getDate_from().trim().isEmpty()) {

            try {
                dateFrom = sdf.parse(argument.getDate_from());
            } catch (ParseException ignored) {
            }

            if (dateFrom == null) {
                result.setCode(ReturnCodes.CONST_INVALID_DATE_FORMAT);
                result.setMessage("\"date_from\" formati \"dd.MM.yyyy\" ko`rinishida bo`lishi kerak");
                return ResponseEntity.badRequest().body(result);
            }
        }

        if (argument.getDate_to() != null && !argument.getDate_to().trim().isEmpty()) {

            try {
                dateTo = sdf.parse(argument.getDate_to());
            } catch (ParseException ignored) {
            }

            if (dateTo == null) {
                result.setCode(ReturnCodes.CONST_INVALID_DATE_FORMAT);
                result.setMessage("\"date_to\" formati \"dd.MM.yyyy\" ko`rinishida bo`lishi kerak");
                return ResponseEntity.badRequest().body(result);
            }
        }

        try (SqlSession sqlSession = DBConfig.getSqlSession()) {

            int currentPage = argument.getPage() != null ? argument.getPage() : 1;
            int pageSize = argument.getPer_page() != null ? argument.getPer_page() : 20;

            if (pageSize > 50) {
                pageSize = 50;
            }

            RowBounds rowbounds = new RowBounds((currentPage - 1) * pageSize, pageSize);

            Map<String, Object> map = new HashMap<>();

            if (argument.getUser_phone() != null && !argument.getUser_phone().trim().isEmpty()) {
                map.put("user_phone", argument.getUser_phone());
            }

            if (argument.getTransaction_type() != null) {
                map.put("transaction_type", argument.getTransaction_type());
            }

            if (dateFrom != null) {
                map.put("date_from", argument.getDate_from());
            }

            if (dateTo != null) {
                map.put("date_to", argument.getDate_to());
            }

            Integer totalRows = sqlSession.selectOne("selectTransactionsCnt", map);
            List<UserTransactionBean> transactions = sqlSession.selectList("selectTransactions", map, rowbounds);

            result.setTotal(totalRows == null ? 0 : totalRows);
            result.setCurrent(currentPage);
            result.setPages(Utils.calculatePagesCount(pageSize, totalRows));

            result.setTransactions(transactions);
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

    @PostMapping("/perform/before")
    private ResponseEntity<?> beforePerformTransaction(@RequestHeader Map<String, String> headers, @RequestBody BeforePerformTransactionArgument argument) {
        BeforePerformTransactionResult result = new BeforePerformTransactionResult();

        UserBean user = getUserByAccess(headers);

        if (user == null) {
            result.setCode(ReturnCodes.CONST_USER_NOT_FOUND);
            result.setMessage("Foydalanuvchi topilmadi");
            return ResponseEntity.status(HttpStatusCode.valueOf(HttpStatus.UNAUTHORIZED.value())).body(result);
        }

        if (argument.getAmount() == null || argument.getAmount() <= 0) {
            result.setCode(ReturnCodes.CONST_INVALID_AMOUNT);
            result.setMessage("Noto`g`ri summa kiritilgan");
            return ResponseEntity.badRequest().body(result);
        }

        if (argument.getTransaction_type() == null) {
            result.setCode(ReturnCodes.CONST_REQUIRED_FIELD_EMPTY);
            result.setMessage("Kerakli maydonlardan biri to`ldirilmagan (TRANSACTION_TYPE)");
            return ResponseEntity.badRequest().body(result);
        }

        try (SqlSession sqlSession = DBConfig.getSqlSession()) {

            Map<String, Object> map = new HashMap<>();
            map.put("p_users_id", user.getId());
            map.put("p_transaction_types_id", argument.getTransaction_type());
            map.put("p_amount", argument.getAmount());
            map.put("p_otp_session", null);
            map.put("p_result", null);
            map.put("p_result_msg", null);

            sqlSession.update("before_perform_transaction", map);

            Integer transactionResult = (Integer) map.get("p_result");

            if (transactionResult != 0) {
                result.setCode(transactionResult);
                result.setMessage("" + map.get("p_result_msg"));
                return ResponseEntity.badRequest().body(result);
            }
            String otpSessionId = "" + map.get("p_otp_session");

            result.setOtp_session(otpSessionId);
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

    @PostMapping("/perform")
    private ResponseEntity<?> performTransaction(@RequestHeader Map<String, String> headers, @RequestBody PerformTransactionArgument argument) {
        GenericResult result = new GenericResult();

        UserBean user = getUserByAccess(headers);

        if (user == null) {
            result.setCode(ReturnCodes.CONST_USER_NOT_FOUND);
            result.setMessage("Foydalanuvchi topilmadi");
            return ResponseEntity.status(HttpStatusCode.valueOf(HttpStatus.UNAUTHORIZED.value())).body(result);
        }

        if (argument.getAmount() == null || argument.getAmount() <= 0) {
            result.setCode(ReturnCodes.CONST_INVALID_AMOUNT);
            result.setMessage("Noto`g`ri summa kiritilgan");
            return ResponseEntity.badRequest().body(result);
        }

        if (argument.getTransaction_type() == null) {
            result.setCode(ReturnCodes.CONST_REQUIRED_FIELD_EMPTY);
            result.setMessage("Kerakli maydonlardan biri to`ldirilmagan (TRANSACTION_TYPE)");
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

        try (SqlSession sqlSession = DBConfig.getSqlSession()) {

            Map<String, Object> map = new HashMap<>();
            map.put("p_users_id", user.getId());
            map.put("p_transaction_types_id", argument.getTransaction_type());
            map.put("p_amount", argument.getAmount());
            map.put("p_detail", "Payment details");
            map.put("p_otp_session", argument.getOtp_session());
            map.put("p_otp_code", argument.getOtp_code());
            map.put("p_result", null);
            map.put("p_result_msg", null);

            sqlSession.update("perform_transaction", map);

            Integer transactionResult = (Integer) map.get("p_result");

            if (transactionResult != 0) {
                result.setCode(transactionResult);
                result.setMessage("" + map.get("p_result_msg"));
                return ResponseEntity.badRequest().body(result);
            }

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
