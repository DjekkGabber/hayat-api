package uz.hayatbank.api.bean;

import lombok.Data;
import lombok.EqualsAndHashCode;

@EqualsAndHashCode(callSuper = true)
@Data
public class UserTransactionBean extends BaseBean {
    private String user_fio;
    private String user_phone;
    private String transaction_type;
    private String status;
    private Double saldo_start;
    private Double amount;
    private Double saldo_end;
    private Integer is_debit;
    private String transaction_time;
    private String payment_details;
}
