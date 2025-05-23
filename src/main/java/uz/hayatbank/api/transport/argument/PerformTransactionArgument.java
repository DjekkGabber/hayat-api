package uz.hayatbank.api.transport.argument;

import lombok.Data;
import lombok.EqualsAndHashCode;
import uz.hayatbank.api.transport.GenericArgument;

@EqualsAndHashCode(callSuper = true)
@Data
public class PerformTransactionArgument extends GenericArgument {
    private Double amount;
    private Integer transaction_type;
    private String otp_session;
    private String otp_code;
}
