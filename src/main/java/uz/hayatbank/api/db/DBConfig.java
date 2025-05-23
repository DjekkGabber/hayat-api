package uz.hayatbank.api.db;

import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;
import org.apache.ibatis.session.SqlSessionFactoryBuilder;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.InputStream;

public class DBConfig {
    private static final Logger _logger = LogManager.getLogger(DBConfig.class);
    private static SqlSessionFactory sqlSessionFactory;

    private static SqlSessionFactory getSqlSessionFactory() {
        if (sqlSessionFactory == null) {
            InputStream inputStream = null;
            try {
                inputStream = DBConfig.class.getResourceAsStream("/db/PostgresConfig.xml");
                sqlSessionFactory = new SqlSessionFactoryBuilder().build(inputStream);
            } catch (Exception ex) {
                _logger.error(ex.getMessage(), ex);
                throw new RuntimeException(ex.getCause());
            } finally {
                if (inputStream != null) {
                    try {
                        inputStream.close();
                    } catch (Exception ex) {
                        _logger.error(ex.getMessage(), ex);
                    }
                }
            }
        }
        return sqlSessionFactory;
    }

    public static SqlSession getSqlSession() {
        return getSqlSessionFactory().openSession(true);
    }

    public static SqlSession getSqlSessionTransaction() {
        return getSqlSessionFactory().openSession(false);
    }

    public static <T> T getSqlMapper(Class<T> clazz) throws Exception {
        SqlSession sqlSession = getSqlSession();
        if (sqlSession == null)
            throw new NullPointerException("SqlSession is NULL!");
        T mapper = sqlSession.getMapper(clazz);
        if (mapper == null)
            throw new NullPointerException("SqlSession is NULL!");
        return mapper;
    }
}