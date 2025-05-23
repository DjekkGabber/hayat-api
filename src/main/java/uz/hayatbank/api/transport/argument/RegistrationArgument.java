package uz.hayatbank.api.transport.argument;

import lombok.Data;
import lombok.EqualsAndHashCode;
import uz.hayatbank.api.transport.GenericArgument;

@EqualsAndHashCode(callSuper = true)
@Data
public class RegistrationArgument extends GenericArgument {
    private String phone;
    private String fio;
    private String email;
    private String otp_session;
    private String otp_code;
}
