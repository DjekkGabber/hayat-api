package uz.hayatbank.api.bean;

import lombok.Data;
import lombok.EqualsAndHashCode;

@EqualsAndHashCode(callSuper = true)
@Data
public class UserBean extends BaseBean {
    private Integer id;
    private Integer user_statuses_id;
    private String fio;
    private String phone;
    private String email;
    private String registered_date;
    private String updated_date;
    private Double balance;
}
