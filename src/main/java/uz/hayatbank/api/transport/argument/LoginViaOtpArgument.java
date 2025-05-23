package uz.hayatbank.api.transport.argument;

import lombok.Data;
import lombok.EqualsAndHashCode;
import uz.hayatbank.api.transport.GenericArgument;

@EqualsAndHashCode(callSuper = true)
@Data
public class LoginViaOtpArgument extends GenericArgument {
    private String phone;
    private String otp_session;
    private String otp_code;
}
