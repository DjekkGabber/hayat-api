package uz.hayatbank.api.transport.result;

import lombok.Data;
import lombok.EqualsAndHashCode;
import uz.hayatbank.api.transport.GenericResult;

@EqualsAndHashCode(callSuper = true)
@Data
public class CheckPhoneResult extends GenericResult {
    private String otp_session;
    private Integer need_register;
}
