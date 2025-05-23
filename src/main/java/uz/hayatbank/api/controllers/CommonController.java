package uz.hayatbank.api.controllers;

import org.apache.ibatis.session.SqlSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import uz.hayatbank.api.db.DBConfig;
import uz.hayatbank.api.transport.GenericResult;

@RestController
@RequestMapping("/api/common")
public class CommonController {
    public static final Logger _logger = LoggerFactory.getLogger(CommonController.class);

    @GetMapping("/ping")
    public ResponseEntity<?> ping() {
        GenericResult result = new GenericResult();

        try (SqlSession sqlSession = DBConfig.getSqlSession()) {

            String currentDate = sqlSession.selectOne("getCurrentTimeStamp");

            result.setCode(0);
            result.setMessage("Ping success. DB Time: " + currentDate);

        } catch (Exception e) {
            _logger.error(e.getMessage(), e);
        }

        return ResponseEntity.ok(result);
    }
}
