package uz.hayatbank.api.controllers;

import org.apache.ibatis.session.SqlSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import uz.hayatbank.api.bean.UserTransactionTypeBean;
import uz.hayatbank.api.db.DBConfig;
import uz.hayatbank.api.transport.GenericDictionaryResult;
import uz.hayatbank.api.utils.ReturnCodes;

import java.util.List;

@RequestMapping("/api/dictionary")
@RestController
public class DictionaryController extends BaseController {

    public static final Logger _logger = LoggerFactory.getLogger(DictionaryController.class);

    @GetMapping("/transaction-types")
    private ResponseEntity<?> getSelfUserInfo() {
        GenericDictionaryResult result = new GenericDictionaryResult();
        try (SqlSession sqlSession = DBConfig.getSqlSession()) {

            List<UserTransactionTypeBean> types = sqlSession.selectList("selectTransactionTypes");

            result.setDictionary(types);
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
