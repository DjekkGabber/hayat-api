package uz.hayatbank.api.bean;

import lombok.Data;
import lombok.EqualsAndHashCode;

@EqualsAndHashCode(callSuper = true)
@Data
public class UserTransactionTypeBean extends BaseIdBean {
    private String name_uz;
    private String name_ru;
    private Integer is_debit;
}
