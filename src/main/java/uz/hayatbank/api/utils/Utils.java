package uz.hayatbank.api.utils;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.Map;
import java.util.StringTokenizer;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Utils {
    public static final Logger _logger = LogManager.getLogger(Utils.class);
    public static final Pattern VALID_EMAIL_ADDRESS_REGEX =
            Pattern.compile("^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,6}$", Pattern.CASE_INSENSITIVE);

    public static boolean isPhoneNumber(String phoneNumber) {
        String regexStr = "^[0-9]{9}";
        return phoneNumber.matches(regexStr);
    }

    public static boolean isEmail(String email) {
        if (email == null || email.isEmpty()) {
            return false;
        }
        Matcher matcher = VALID_EMAIL_ADDRESS_REGEX.matcher(email);
        return matcher.find();
    }

    public static String getAuthTokenFromHeader(Map<String, String> headers) {
        if (headers == null || headers.isEmpty()) {
            return null;
        }

        for (String headerName : headers.keySet()) {

//            _logger.info("--- Header: {}, Value: {}", headerName, headers.get(headerName));

            if (headerName.equalsIgnoreCase(Constants.HEADER_AUTHORIZATION)) {

                String headerValue = headers.get(headerName);

                if (headerValue == null || headerValue.trim().isEmpty() || headerValue.equals("*")) {
                    return null;
                }

                StringTokenizer st = new StringTokenizer(headerValue);

                if (st.hasMoreTokens()) {
                    String basic = st.nextToken();
                    if (basic.equalsIgnoreCase("Bearer")) {
                        return st.nextToken();
                    }
                }

                return headerValue.replace("Bearer ", "");
            }
        }
        return null;
    }

    public static int calculatePagesCount(Integer perPageSize, Integer totalRows) {
        return totalRows < perPageSize ? 1 : Double.valueOf(Math.ceil((double) totalRows / perPageSize)).intValue();
    }
}
